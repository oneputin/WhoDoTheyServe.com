dev:
  primary:
    NODE_ARGS                       : '--debug=5000'
    NODE_ENV                        : \development
    PORT                            : 4000
    WDTS_DB_URI                     : \mongodb://localhost/wdts_dev
    WDTS_DB_CACHE_ENABLE            : true
    WDTS_DB_CACHE_SWEEP_PERIOD_MINS : 10
  test_1:
    COVERAGE_FLAG                   : true
    NODE_ARGS                       : '--debug=5001'
    NODE_ENV                        : \test
    PORT                            : 4001
    WDTS_DB_URI                     : \mongodb://localhost/wdts_test_1
    WDTS_DB_CACHE_ENABLE            : true
    WDTS_USER_SIGNIN_BAD_FREEZE_SECS: 0
  test_2:
    COVERAGE_FLAG                   : true
    NODE_ARGS                       : '--debug=5002'
    NODE_ENV                        : \test
    PORT                            : 4002
    WDTS_DB_URI                     : \mongodb://localhost/wdts_test_2
    WDTS_DB_CACHE_ENABLE            : true
    WDTS_USER_SIGNIN_BAD_FREEZE_SECS: 0
  tester_1:
    NODE_ENV                        : \tester
    SITE_PORT                       : 4001
  tester_2:
    NODE_ENV                        : \tester
    SITE_PORT                       : 4002

staging:
  primary:
    NODE_ARGS                       : '--debug=5003'
    NODE_ENV                        : \staging
    PORT                            : 4003
    WDTS_DB_URI                     : \mongodb://localhost/wdts_staging
  test_1:
    NODE_ENV                        : \test
    PORT                            : 4004
    WDTS_DB_URI                     : \mongodb://localhost/wdts_test_1
    WDTS_USER_SIGNIN_BAD_FREEZE_SECS: 0
  test_2:
    NODE_ENV                        : \test
    PORT                            : 4005
    WDTS_DB_URI                     : \mongodb://localhost/wdts_test_2
    WDTS_USER_SIGNIN_BAD_FREEZE_SECS: 0
  tester_1:
    NODE_ENV                        : \tester
    SITE_PORT                       : 4004
  tester_2:
    NODE_ENV                        : \tester
    SITE_PORT                       : 4005
