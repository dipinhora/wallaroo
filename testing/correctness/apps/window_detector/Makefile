# include root makefile
ifndef ROOT_MAKEFILE_MK
include ../../../../Makefile
endif

# prevent rules from being evaluated/included multiple times
ifndef $(abspath $(lastword $(MAKEFILE_LIST)))_MK
$(abspath $(lastword $(MAKEFILE_LIST)))_MK := 1


# The following are control variables that determine what logic from `rules.mk` is enabled

# `true`/`false` to enable/disable the actual unit test command so it can be overridden (the targets are still created)
# applies to both the pony and elixir test targets
$(abspath $(lastword $(MAKEFILE_LIST)))_UNIT_TEST_COMMAND := false

# `true`/`false` to enable/disable generate pony related targets (build/test/clean) for pony sources in this directory
# otherwise targets only get created if there are pony sources (*.pony) in this directory.
$(abspath $(lastword $(MAKEFILE_LIST)))_PONY_TARGET := true

# `true`/`false` to enable/disable generate final file build target using ponyc command for the pony build target so
# it can be overridden manually
$(abspath $(lastword $(MAKEFILE_LIST)))_PONYC_TARGET := true

# `true`/`false` to enable/disable generate exs related targets (build/test/clean) for elixir sources in this directory
# otherwise targets only get created if there are elixir sources (*.exs) in this directory.
$(abspath $(lastword $(MAKEFILE_LIST)))_EXS_TARGET := true

# `true`/`false` to enable/disable generate docker related targets (build/push) for a Dockerfile in this directory
# otherwise targets only get created if there is a Dockerfile in this directory
$(abspath $(lastword $(MAKEFILE_LIST)))_DOCKER_TARGET := true

# `true`/`false` to enable/disable recursing into Makefiles of subdirectories if they exist
# (and by recursion every makefile in the tree that is referenced)
$(abspath $(lastword $(MAKEFILE_LIST)))_RECURSE_SUBMAKEFILES := true


WINDOW_DETECTORS_PATH := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# standard rules generation makefile
include $(rules_mk_path)


build-testing-correctness-apps-window_detectors: build-machida
#build-testing-correctness-apps-window_detectors: build-machida3
#build-testing-correctness-apps-window_detectors: build-testing-correctness-apps-window_detectors-validator
#integration-tests-testing-correctness-apps-window_detectors: build-testing-correctness-apps-window_detectors
#integration-tests-testing-correctness-apps-window_detectors: window_detectors_tests_pony
integration-tests-testing-correctness-apps-window_detectors: window_detectors_tests_python
#integration-tests-testing-correctness-apps-window_detectors: window_detectors_tests_python3

# group the tests by target API (Pony, Python, Python3)
# Pony
#window_detectors_tests_pony: window_detectors_test_pony
#window_detectors_tests_pony: window_detectors_test_pony_gen_source
#window_detectors_tests_pony: window_detectors_test_pony_10_worker
#window_detectors_tests_pony: window_detectors_test_pony_gen_source_10_worker

# Python
window_detectors_tests_python: window_detectors_test_python
#window_detectors_tests_python: window_detectors_test_python_gen_source
#window_detectors_tests_python: window_detectors_test_python_10_worker
#window_detectors_tests_python: window_detectors_test_python_gen_source_10_worker

# Python3
#window_detectors_tests_python3: window_detectors_test_python3
#window_detectors_tests_python3: window_detectors_test_python3_gen_source
#window_detectors_tests_python3: window_detectors_test_python3_10_worker
#window_detectors_tests_python3: window_detectors_test_python3_gen_source_10_worker


# Individual test definitions below
#
# Python tests
window_detectors_test_python:
	cd $(WINDOW_DETECTORS_PATH) && \
	integration_test \
	  --sequence-sender '(0,100]' 0 '>I' key_0 \
	  --sequence-sender '(0,100]' 0 '>I' key_1 \
	  --log-level error \
		--command 'machida --application-module tumbling_time_window $(RUN_WITH_RESILIENCE)' \
		--validation-cmd 'echo 1' \
		--output 'received.txt' \
		--batch-size 1 \
		--workers 1 \
		--sink-expect 200

#window_detectors_test_python_gen_source:
#	cd $(window_detectors_PATH) && \
#	integration_test \
#	  --log-level error \
#		--sources 0 \
#		--command 'machida --application-module window_detectors --gen-source $(RUN_WITH_RESILIENCE)' \
#		--validation-cmd './validator/validator -a -i' \
#		--output 'received.txt' \
#		--batch-size 10 \
#		--workers 10 \
#		--sink-expect 200 \
#		--sink-expect-allow-more
#
#window_detectors_test_python_10_worker:
#	cd $(window_detectors_PATH) && \
#	integration_test \
#	  --sequence-sender '(0,1000]' 0 '>I' key_0 \
#	  --sequence-sender '(0,1000]' 0 '>I' key_1 \
#	  --sequence-sender '(0,1000]' 0 '>I' key_2 \
#	  --sequence-sender '(0,1000]' 0 '>I' key_3 \
#	  --sequence-sender '(0,1000]' 0 '>I' key_4 \
#	  --sequence-sender '(0,1000]' 0 '>I' key_5 \
#	  --sequence-sender '(0,1000]' 0 '>I' key_6 \
#	  --sequence-sender '(0,1000]' 0 '>I' key_7 \
#	  --sequence-sender '(0,1000]' 0 '>I' key_8 \
#	  --sequence-sender '(0,1000]' 0 '>I' key_9 \
#	  --log-level error \
#		--command 'machida --application-module window_detectors $(RUN_WITH_RESILIENCE)' \
#		--validation-cmd './validator/validator -e 1000 -a -i' \
#		--output 'received.txt' \
#		--batch-size 10 \
#		--workers 10 \
#		--sink-expect 10000
#
#window_detectors_test_python_gen_source_10_worker:
#	cd $(window_detectors_PATH) && \
#	integration_test \
#	  --log-level error \
#		--sources 0 \
#		--command 'machida --application-module window_detectors --gen-source $(RUN_WITH_RESILIENCE)' \
#		--validation-cmd './validator/validator -a -i' \
#		--output 'received.txt' \
#		--batch-size 10 \
#		--workers 10 \
#		--sink-expect 10000 \
#		--sink-expect-allow-more
#
## Python3 tests
#window_detectors_test_python3:
#	cd $(window_detectors_PATH) && \
#	integration_test \
#	  --sequence-sender '(0,100]' 0 '>I' key_0 \
#	  --sequence-sender '(0,100]' 0 '>I' key_1 \
#	  --log-level error \
#		--command 'machida3 --application-module window_detectors $(RUN_WITH_RESILIENCE)' \
#		--validation-cmd './validator/validator -e 100 -a -i' \
#		--output 'received.txt' \
#		--batch-size 10 \
#		--workers 2 \
#		--sink-expect 200
#
#window_detectors_test_python3_gen_source:
#	cd $(window_detectors_PATH) && \
#	integration_test \
#	  --log-level error \
#		--sources 0 \
#		--command 'machida3 --application-module window_detectors --gen-source $(RUN_WITH_RESILIENCE)' \
#		--validation-cmd './validator/validator -a -i' \
#		--output 'received.txt' \
#		--batch-size 10 \
#		--workers 10 \
#		--sink-expect 200 \
#		--sink-expect-allow-more
#
#window_detectors_test_python3_10_worker:
#	cd $(window_detectors_PATH) && \
#	integration_test \
#	  --sequence-sender '(0,1000]' 0 '>I' key_0 \
#	  --sequence-sender '(0,1000]' 0 '>I' key_1 \
#	  --sequence-sender '(0,1000]' 0 '>I' key_2 \
#	  --sequence-sender '(0,1000]' 0 '>I' key_3 \
#	  --sequence-sender '(0,1000]' 0 '>I' key_4 \
#	  --sequence-sender '(0,1000]' 0 '>I' key_5 \
#	  --sequence-sender '(0,1000]' 0 '>I' key_6 \
#	  --sequence-sender '(0,1000]' 0 '>I' key_7 \
#	  --sequence-sender '(0,1000]' 0 '>I' key_8 \
#	  --sequence-sender '(0,1000]' 0 '>I' key_9 \
#	  --log-level error \
#		--command 'machida3 --application-module window_detectors $(RUN_WITH_RESILIENCE)' \
#		--validation-cmd './validator/validator -e 1000 -a -i' \
#		--output 'received.txt' \
#		--batch-size 10 \
#		--workers 10 \
#		--sink-expect 10000
#
#window_detectors_test_python3_gen_source_10_worker:
#	cd $(window_detectors_PATH) && \
#	integration_test \
#	  --log-level error \
#		--sources 0 \
#		--command 'machida3 --application-module window_detectors --gen-source $(RUN_WITH_RESILIENCE)' \
#		--validation-cmd './validator/validator -a -i' \
#		--output 'received.txt' \
#		--batch-size 10 \
#		--workers 10 \
#		--sink-expect 10000 \
#		--sink-expect-allow-more
#
## Pony tests
#window_detectors_test_pony:
#	cd $(window_detectors_PATH) && \
#	integration_test \
#	  --sequence-sender '(0,100]' 0 '>I' key_0 \
#	  --sequence-sender '(0,100]' 0 '>I' key_1 \
#	  --log-level error \
#		--command './window_detectors $(RUN_WITH_RESILIENCE)' \
#		--validation-cmd './validator/validator -e 100 -a -i' \
#		--output 'received.txt' \
#		--batch-size 10 \
#		--workers 2 \
#		--sink-expect 200
#
#window_detectors_test_pony_gen_source:
#	cd $(window_detectors_PATH) && \
#	integration_test \
#	  --log-level error \
#		--command './window_detectors --gen-source $(RUN_WITH_RESILIENCE)' \
#		--sources 0 \
#		--validation-cmd './validator/validator -a -i' \
#		--output 'received.txt' \
#		--batch-size 10 \
#		--workers 2 \
#		--sink-expect 200 \
#		--sink-expect-allow-more
#
#window_detectors_test_pony_10_worker:
#	cd $(window_detectors_PATH) && \
#	integration_test \
#	  --sequence-sender '(0,1000]' 0 '>I' key_0 \
#	  --sequence-sender '(0,1000]' 0 '>I' key_1 \
#	  --sequence-sender '(0,1000]' 0 '>I' key_2 \
#	  --sequence-sender '(0,1000]' 0 '>I' key_3 \
#	  --sequence-sender '(0,1000]' 0 '>I' key_4 \
#	  --sequence-sender '(0,1000]' 0 '>I' key_5 \
#	  --sequence-sender '(0,1000]' 0 '>I' key_6 \
#	  --sequence-sender '(0,1000]' 0 '>I' key_7 \
#	  --sequence-sender '(0,1000]' 0 '>I' key_8 \
#	  --sequence-sender '(0,1000]' 0 '>I' key_9 \
#	  --log-level error \
#		--command './window_detectors $(RUN_WITH_RESILIENCE)' \
#		--validation-cmd './validator/validator -e 1000 -a -i' \
#		--output 'received.txt' \
#		--batch-size 10 \
#		--workers 10 \
#		--sink-expect 10000
#
#window_detectors_test_pony_gen_source_10_worker:
#	cd $(window_detectors_PATH) && \
#	integration_test \
#	  --log-level error \
#		--command './window_detectors --gen-source $(RUN_WITH_RESILIENCE)' \
#		--sources 0 \
#		--validation-cmd './validator/validator -a -i' \
#		--output 'received.txt' \
#		--batch-size 10 \
#		--workers 10 \
#		--sink-expect 10000 \
#		--sink-expect-allow-more

# end of prevent rules from being evaluated/included multiple times
endif
