local PLUGIN_NAME = (...):match("([^%.]+)%.[^%.]+$")

local http = require("resty.http")
local get_prometheus = require('kong.plugins.prometheus.exporter').get_prometheus

local shared_dict = ngx.shared[PLUGIN_NAME]

local function fetch_health_status(self)
  local httpc = http.new()

  local res, err = httpc:request_uri("http://httpbin/status/200,404,401,201,204", {method = "GET"})

  kong.log.warn("Resposta da API de health check: ", res.status)

  if not res then
    kong.log.warn("Falha ao consultar a API de health check: ", err)
    return
  end

  local status = res.status

  self.metrics.healthcheck_status:inc(1, {status})
  shared_dict:set("health_status", status)

  httpc:close()
end

local function healthcheck_timer(premature, self)
  if ngx.worker.id() ~= 0 or premature then
    return
  end

  fetch_health_status(self)

end

return {
  PRIORITY = 1000,
  VERSION = "0.0.1",
  metrics = {},
  
  init_worker = function(self)
    local prometheus = get_prometheus()
    self.metrics.healthcheck_status = prometheus:gauge('healthcheck_status', 'total de chamadas ao healthcheck', {'status'})

    ngx.timer.every(5, healthcheck_timer, self)
  end,

  access = function(self, conf)
    kong.response.set_header("valor-do-shared-dict",  shared_dict:get("health_status"))
  end
}