# Hub and Spoke Demo API
# A simple plumber API for demonstrating NixOS + OpenTofu deployments

library(plumber)

#* @apiTitle Hub and Spoke Demo
#* @apiDescription Demo API for platform engineering showcase

#* Health check endpoint
#* @get /healthz
#* @serializer unboxedJSON
function() {
  list(
    status = "healthy",
    timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    service = "hubspoke-demo",
    environment = Sys.getenv("ENVIRONMENT", "unknown")
  )
}

#* Root endpoint - returns hello message
#* @get /
#* @serializer unboxedJSON  
function() {
  list(
    message = "Hello from Hub and Spoke Demo!",
    version = Sys.getenv("IMAGE_VERSION", "unknown"),
    hostname = Sys.info()["nodename"],
    environment = Sys.getenv("ENVIRONMENT", "unknown"),
    timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  )
}

#* Echo endpoint - returns what you send
#* @post /echo
#* @param msg The message to echo
#* @serializer unboxedJSON
function(msg = "") {
  list(
    received = msg,
    echoed = paste0("Echo: ", msg),
    timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  )
}

#* Status endpoint - detailed system info
#* @get /status
#* @serializer unboxedJSON
function() {
  list(
    service = "hubspoke-demo",
    status = "running",
    version = Sys.getenv("IMAGE_VERSION", "unknown"),
    environment = Sys.getenv("ENVIRONMENT", "unknown"),
    hostname = Sys.info()["nodename"],
    platform = R.version$platform,
    r_version = R.version$version.string,
    timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  )
}
