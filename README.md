# sagt-sweep

The clock for the SAGT data service. The service itself is serverless and does
nothing between requests, so this repository exists to call its tick endpoint
on a schedule. Public because public repositories get unlimited GitHub Actions
minutes, and a sweeper needs to run all day; there is nothing here but the
schedule itself, and the endpoint it calls requires a secret this repository
holds only as an encrypted Actions secret.
