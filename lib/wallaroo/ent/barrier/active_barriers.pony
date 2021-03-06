/*

Copyright 2018 The Wallaroo Authors.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
 implied. See the License for the specific language governing
 permissions and limitations under the License.

*/

use "collections"
use "wallaroo_labs/mort"

class ActiveBarriers
  let _barriers: Map[BarrierToken, BarrierHandler] = _barriers.create()

  fun barrier_in_progress(): Bool =>
    _barriers.size() > 0

  fun ref add_barrier(barrier_token: BarrierToken, handler: BarrierHandler) ?
  =>
    ifdef "checkpoint_trace" then
      @printf[I32]("ACTIVE_BARRIERS: Adding barrier %s\n".cstring(),
        barrier_token.string().cstring())
    end
    if _barriers.contains(barrier_token) then
      try
        let old_handler = _barriers(barrier_token)?
        @printf[I32]("attempted to add %s again during its %s phase\n"
          .cstring(), barrier_token.string().cstring(),
          old_handler.name().cstring())
      else
        Unreachable()
      end
      error
    end
    _barriers(barrier_token) = handler

  fun ref remove_barrier(barrier_token: BarrierToken) ? =>
    if _barriers.contains(barrier_token) then
      try
        ifdef "checkpoint_trace" then
          @printf[I32]("ACTIVE_BARRIERS: Removing barrier %s\n".cstring(),
            barrier_token.string().cstring())
        end
        _barriers.remove(barrier_token)?
      else
        Fail()
      end
    else
      @printf[I32]("attempted to remove %s but it wasn't active\n"
        .cstring(), barrier_token.string().cstring())
      error
    end

  fun ref update_handler(barrier_token: BarrierToken,
    handler: BarrierHandler) ?
  =>
    if not _barriers.contains(barrier_token) then
      @printf[I32](("attempted to update handler for %s to %s, but %s is " +
        "not active\n").cstring(), barrier_token.string().cstring(),
        handler.name().cstring(), barrier_token.string().cstring())
      error
    end
    _barriers(barrier_token) = handler

  fun ref ack_barrier(s: BarrierReceiver, barrier_token: BarrierToken) =>
    try
      _barriers(barrier_token)?.ack_barrier(s)
    else
      ifdef debug then
        @printf[I32](("ActiveBarriers: ack_barrier on unknown " +
          "barrier %s.\n").cstring(), barrier_token.string().cstring())
      end
    end

  fun ref worker_ack_barrier_start(w: String, barrier_token: BarrierToken) =>
    try
      _barriers(barrier_token)?.worker_ack_barrier_start(w)
    else
      ifdef debug then
        @printf[I32](("ActiveBarriers: worker_ack_barrier_start on unknown " +
          "barrier %s.\n").cstring(), barrier_token.string().cstring())
      end
    end

  fun ref worker_ack_barrier(w: String, barrier_token: BarrierToken) =>
    try
      _barriers(barrier_token)?.worker_ack_barrier(w)
    else
      ifdef debug then
        @printf[I32](("ActiveBarriers: worker_ack_barrier on unknown " +
          "barrier %s.\n").cstring(), barrier_token.string().cstring())
      end
    end

  fun ref check_for_completion(barrier_token: BarrierToken) =>
    try
      _barriers(barrier_token)?.check_for_completion()
    else
      ifdef debug then
        @printf[I32](("ActiveBarriers: check_for_completion on unknown " +
          "barrier %s.\n").cstring(), barrier_token.string().cstring())
      end
    end

  fun ref clear() =>
    ifdef "checkpoint_trace" then
      @printf[I32]("ACTIVE_BARRIERS: Clearing!!\n".cstring())
    end
    _barriers.clear()
