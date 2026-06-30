Rack::Attack.throttle("auth/ip", limit: 5, period: 20) do |req|
  req.ip if req.post? && req.path.match?(%r{/api/v1/(users|sessions)})
end

Rack::Attack.throttled_responder = lambda do |_req|
  [
    429,
    { "Content-Type" => "application/json" },
    [ { error: "Too many requests. Please try again later." }.to_json ]
  ]
end
