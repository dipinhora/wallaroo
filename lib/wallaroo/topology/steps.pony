use "assert"
use "buffered"
use "time"
use "net"
use "collections"
use "sendence/wall-clock"
use "sendence/guid"
use "wallaroo/backpressure"
use "wallaroo/boundary"
use "wallaroo/invariant"
use "wallaroo/metrics"
use "wallaroo/network"
use "wallaroo/resilience"
use "wallaroo/tcp-sink"

// TODO: CREDITFLOW- Every runnable step is also a credit flow consumer
// Really this should probably be another method on CreditFlowConsumer
// At which point CreditFlowConsumerStep goes away as well
trait tag RunnableStep
  be run[D: Any val](metric_name: String, source_ts: U64, data: D,
    origin: Producer, msg_uid: U128,
    frac_ids: None, seq_id: SeqId, route_id: RouteId,
    latest_ts: U64, metrics_id: U16, worker_ingress_ts: U64)

  be replay_run[D: Any val](metric_name: String, source_ts: U64, data: D,
    origin: Producer, msg_uid: U128,
    frac_ids: None, incoming_seq_id: SeqId, route_id: RouteId,
    latest_ts: U64, metrics_id: U16, worker_ingress_ts: U64)


interface Initializable
  be initialize(outgoing_boundaries: Map[String, OutgoingBoundary] val,
    tcp_sinks: Array[TCPSink] val, omni_router: OmniRouter val)

type CreditFlowConsumerStep is (RunnableStep & CreditFlowConsumer & Initializable tag)

actor Step is (RunnableStep & Resilient & Producer &
  Consumer & Initializable)
  """
  # Step

  ## Future work
  * Switch to requesting credits via promise
  """
  let _runner: Runner
  var _router: Router val
  // For use if this is a state step, otherwise EmptyOmniRouter
  var _omni_router: OmniRouter val
  var _route_builder: RouteBuilder val
  let _metrics_reporter: MetricsReporter
  let _default_target: (Step | None)
  var _initialized: Bool = false
  // list of envelopes
  // (origin, msg_uid, frac_ids, seq_id, route_id)
  let _deduplication_list: Array[(Producer, U128, (Array[U64] val | None),
    SeqId, RouteId)] = _deduplication_list.create()
  let _alfred: Alfred
  var _id: U128
  var _seq_id: SeqId = 1 // 0 is reserved for "not seen yet"

  let _filter_route_id: RouteId = GuidGenerator.u64()

  // Credit Flow Producer
  let _routes: MapIs[CreditFlowConsumer, Route] = _routes.create()

   // CreditFlow Consumer
  var _upstreams: Array[Producer] = _upstreams.create()
  var _max_distributable_credits: ISize = 1_000
  var _distributable_credits: ISize = 0

  // Resilience routes
  // TODO: This needs to be merged with credit flow producer routes
  let _resilience_routes: Routes = Routes

  new create(runner: Runner iso, metrics_reporter: MetricsReporter iso,
    id: U128, route_builder: RouteBuilder val, alfred: Alfred,
    router: Router val = EmptyRouter, default_target: (Step | None) = None,
    omni_router: OmniRouter val = EmptyOmniRouter)
  =>
    _max_distributable_credits =
      _max_distributable_credits.usize().next_pow2().isize()
    _runner = consume runner
    match _runner
    | let r: ReplayableRunner => r.set_step_id(id)
    end
    _metrics_reporter = consume metrics_reporter
    _router = _runner.clone_router_and_set_input_type(router)
    _omni_router = omni_router
    _route_builder = route_builder
    _alfred = alfred
    _alfred.register_origin(this, id)
    _id = id
    _default_target = default_target

  be initialize(outgoing_boundaries: Map[String, OutgoingBoundary] val,
    tcp_sinks: Array[TCPSink] val, omni_router: OmniRouter val)
  =>
    ifdef debug then
      Invariant(_max_distributable_credits ==
        (_max_distributable_credits.usize() - 1).next_pow2().isize())
    end
    for consumer in _router.routes().values() do
      _routes(consumer) =
        _route_builder(this, consumer, StepRouteCallbackHandler,
        _metrics_reporter)
    end

    for (worker, boundary) in outgoing_boundaries.pairs() do
      _routes(boundary) =
        _route_builder(this, boundary, StepRouteCallbackHandler,
        _metrics_reporter)
    end

    match _default_target
    | let r: CreditFlowConsumerStep =>
      _routes(r) = _route_builder(this, r, StepRouteCallbackHandler,
        _metrics_reporter)
    end

    // for sink in tcp_sinks.values() do
    //   _routes(sink) = _route_builder(this, sink, StepRouteCallbackHandler,
    //     _metrics_reporter)
    // end

    for r in _routes.values() do
      r.initialize(_max_distributable_credits, "Step")
      ifdef "resilience" then
        _resilience_routes.add_route(r)
      end
    end

    _omni_router = omni_router

    _initialized = true

  be update_route_builder(route_builder: RouteBuilder val) =>
    _route_builder = route_builder

  be register_routes(router: Router val, route_builder: RouteBuilder val) =>
    for consumer in router.routes().values() do
      let next_route = route_builder(this, consumer, StepRouteCallbackHandler,
         _metrics_reporter)
      _routes(consumer) = next_route
      if _initialized then
        // TODO: This is a kind of hack right now. Each route has the
        // same number of max credits as the step itself.  The commented
        // code surrounding this shows the old approach of dividing the
        // max credits among routes.
        next_route.initialize(_max_distributable_credits, "Step")
      end
    end

  // TODO: This needs to dispose of the old routes and replace with new routes
  be update_router(router: Router val) => _router = router

  be update_omni_router(omni_router: OmniRouter val) =>
    _omni_router = omni_router

  be run[D: Any val](metric_name: String, source_ts: U64, data: D,
    i_origin: Producer, msg_uid: U128,
    i_frac_ids: None, i_seq_id: SeqId, i_route_id: RouteId,
    latest_ts: U64, metrics_id: U16, worker_ingress_ts: U64)
  =>
    let my_latest_ts = ifdef "detailed-metrics" then
        Time.nanos()
      else
        latest_ts
      end

    let my_metrics_id = ifdef "detailed-metrics" then
        _metrics_reporter.step_metric(metric_name, "Before receive at step behavior",
          metrics_id, latest_ts, my_latest_ts)
        metrics_id + 1
      else
        metrics_id
      end

    ifdef "trace" then
      @printf[I32](("Rcvd msg at " + _runner.name() + " step\n").cstring())
    end
    (let is_finished, _, let last_ts) = _runner.run[D](metric_name, source_ts, data,
      this, _router, _omni_router,
      i_origin, msg_uid, i_frac_ids, i_seq_id, i_route_id,
      my_latest_ts, my_metrics_id, worker_ingress_ts, _metrics_reporter)
    if is_finished then
      ifdef "resilience" then
        ifdef "trace" then
          @printf[I32]("Filtering\n".cstring())
        end
        // TODO ideally we want filter to create the id
        // but there's problems initializing Routes with a ref
        // back to its container. Especially in Boundary etc
        _resilience_routes.filter(this, next_sequence_id(),
          i_origin, i_route_id, i_seq_id)
      end
      ifdef "backpressure" then
        _recoup_credits(1)
      end
      let computation_end = Time.nanos()

      ifdef "detailed-metrics" then
        _metrics_reporter.step_metric(metric_name, "Before end at Step", 9999,
          last_ts, computation_end)
      end

      _metrics_reporter.pipeline_metric(metric_name, source_ts)
      _metrics_reporter.worker_metric(metric_name, worker_ingress_ts)
    end
    // DO NOT REMOVE. THIS GC TRIGGERING IS INTENTIONAL.
    @pony_triggergc[None](this)

  fun ref next_sequence_id(): U64 =>
    _seq_id = _seq_id + 1

  ///////////
  // RECOVERY
  fun _is_duplicate(origin: Producer, msg_uid: U128,
    frac_ids: None, seq_id: SeqId, route_id: RouteId): Bool
  =>
    for e in _deduplication_list.values() do
      //TODO: Bloom filter maybe?
      if e._2 == msg_uid then
        // No frac_ids yet
        return true
        // match (e._3, frac_ids)
        // | (let efa: Array[U64] val, let efb: Array[U64] val) =>
        //   if efa.size() == efb.size() then
        //     var found = true
        //     for i in Range(0,efa.size()) do
        //       try
        //         if efa(i) != efb(i) then
        //           found = false
        //           break
        //         end
        //       else
        //         found = false
        //         break
        //       end
        //     end
        //     if found then
        //       return true
        //     end
        //   end
        // | (None,None) => return true
        // end
      end
    end
    false

  be replay_run[D: Any val](metric_name: String, source_ts: U64, data: D,
    i_origin: Producer, msg_uid: U128,
    i_frac_ids: None, i_seq_id: SeqId, i_route_id: RouteId,
    latest_ts: U64, metrics_id: U16, worker_ingress_ts: U64)
  =>
    if not _is_duplicate(i_origin, msg_uid, i_frac_ids, i_seq_id,
      i_route_id) then
      _deduplication_list.push((i_origin, msg_uid, i_frac_ids, i_seq_id,
        i_route_id))
      (let is_finished, _, let last_ts) = _runner.run[D](metric_name, source_ts, data,
        this, _router, _omni_router,
        i_origin, msg_uid, i_frac_ids, i_seq_id, i_route_id,
        latest_ts, metrics_id, worker_ingress_ts, _metrics_reporter)

      if is_finished then
        //TODO: be more efficient (batching?)
        ifdef "resilience" then
          _resilience_routes.filter(this, next_sequence_id(),
            i_origin, i_route_id, i_seq_id)
        end
        ifdef "backpressure" then
          _recoup_credits(1)
        end
        let computation_end = Time.nanos()

        ifdef "detailed-metrics" then
          _metrics_reporter.step_metric(metric_name, "Before end at Step replay",
            9999, last_ts, computation_end)
        end

        _metrics_reporter.pipeline_metric(metric_name, source_ts)
        _metrics_reporter.worker_metric(metric_name, worker_ingress_ts)
      end
    end

  //////////////
  // ORIGIN (resilience)
  fun ref _x_resilience_routes(): Routes =>
    _resilience_routes

  fun ref _flush(low_watermark: SeqId) =>
    ifdef "trace" then
      @printf[I32]("flushing at and below: %llu\n".cstring(), low_watermark)
    end
    match _id
    | let id: U128 =>
      _alfred.flush_buffer(id, low_watermark)
    else
      @printf[I32]("Tried to flush a non-existing buffer!".cstring())
    end

  be replay_log_entry(uid: U128, frac_ids: None, statechange_id: U64, payload: ByteSeq val)
  =>
    // TODO: We need to handle the entire incoming envelope here
    None
    // if not _is_duplicate(_incoming_envelope) then
    //   _deduplication_list.push(_incoming_envelope)
    //   match _runner
    //   | let r: ReplayableRunner =>
    //     r.replay_log_entry(uid, frac_ids, statechange_id, payload, this)
    //   else
    //     @printf[I32]("trying to replay a message to a non-replayable runner!".cstring())
    //   end
    // end

  be replay_finished() =>
    _deduplication_list.clear()

  be start_without_replay() =>
    _deduplication_list.clear()

  be dispose() =>
    None
    // match _router
    // | let sender: DataSender =>
    //   sender.dispose()
    // end

  //////////////
  // CREDIT FLOW PRODUCER
  be receive_credits(credits: ISize, from: CreditFlowConsumer) =>
    ifdef debug then
      Invariant(_routes.contains(from))
    end

    try
      let route = _routes(from)
      route.receive_credits(credits)
    end

  fun ref route_to(c: CreditFlowConsumerStep): (Route | None) =>
    try
      _routes(c)
    else
      None
    end

  //////////////
  // CREDIT FLOW CONSUMER
  be register_producer(producer: Producer) =>
    ifdef debug then
      Invariant(not _upstreams.contains(producer))
    end

    ifdef "credit_trace" then
      @printf[I32]("Registered producer!\n".cstring())
    end
    _upstreams.push(producer)

  be unregister_producer(producer: Producer,
    credits_returned: ISize)
  =>
    ifdef debug then
      Invariant(_upstreams.contains(producer))
    end

    try
      let i = _upstreams.find(producer)
      _upstreams.delete(i)
      _recoup_credits(credits_returned)
    end

  fun ref recoup_credits(recoup: ISize) =>
    _recoup_credits(recoup)

  fun ref _recoup_credits(recoup: ISize) =>
    _distributable_credits = _distributable_credits + recoup
    if _distributable_credits > _max_distributable_credits then
      _distributable_credits = _max_distributable_credits
    end

  be credit_request(from: Producer) =>
    """
    Receive a credit request from a producer. For speed purposes, we assume
    the producer is already registered with us.
    """
    ifdef debug then
      Invariant(_upstreams.contains(from))
    end

    let give_out =
      if _distributable_credits > 0 then
        let portion = _distributable_credits / _upstreams.size().isize()
        portion.max(1)
      else
        0
      end

    ifdef "credit_trace" then
      @printf[I32]("Step: Credits requested. Giving %llu credits out of %llu\n".cstring(), give_out, _distributable_credits)
    end

    from.receive_credits(give_out, this)
    _distributable_credits = _distributable_credits - give_out

  be return_credits(credits: ISize) =>
    _distributable_credits = _distributable_credits + credits

  fun _lowest_route_credit_level(): ISize =>
    var lowest: ISize = ISize.max_value()

    for route in _routes.values() do
      if route.credits_available() < lowest then
        lowest = route.credits_available()
      end
    end

    lowest

class StepRouteCallbackHandler is RouteCallbackHandler
  fun ref register(producer: Producer ref, r: Route tag) =>
    None

  fun shutdown(producer: Producer ref) =>
    // TODO: CREDITFLOW - What is our error handling?
    None

  fun ref credits_replenished(producer: Producer ref) =>
    None

  fun ref credits_exhausted(producer: Producer ref) =>
    None
