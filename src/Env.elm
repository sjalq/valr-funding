module Env exposing (..)

-- The Env.elm file is for per-environment configuration.
-- See https://dashboard.lamdera.app/docs/environment for more info.


dummyConfigItem =
    ""


modelKey =
    "1234567890"


slackApiToken =
    "1234567890"


slackChannel =
    "#test"


logSize =
    "2000"


stillTesting =
    "1"


type Mode
    = Development
    | Production


mode =
    Development


googleAppClientSecret : String
googleAppClientSecret =
    ""


githubAppClientId : String
githubAppClientId =
    ""


googleAppClientId : String
googleAppClientId =
    ""


githubAppClientSecret : String
githubAppClientSecret =
    ""

auth0AppClientId : String
auth0AppClientId =
    ""  -- Replace with your actual Client ID


auth0AppClientSecret : String
auth0AppClientSecret =
    ""  -- Replace with your actual Client Secret


auth0AppTenant : String
auth0AppTenant =
    "" -- Replace with tenant, e.g., "your-domain.auth0.com" 