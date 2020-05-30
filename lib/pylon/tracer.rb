module Pylon
  class Tracer
    def initialize(app)
      @app = app
      @logger = Logger.new("/Users/thyago.barbosa/code/dalia/pylon_tracer.log")
      if defined?(Rails)
        @app_name = Rails.application.class.parent_name
      else
        @app_name = "Unknown App"
      end
    end

    def call(env)
      req = Rack::Request.new(env)

      logger.info "*** Tracer: Request received by #{@app_name}"
      logger.info "*** Request ID: #{env["action_dispatch.request_id"]}"
      logger.info "*** #{req.request_method} #{req.path}"
      logger.info "*** Params: #{req.params}"
      logger.info "*** -----"
      status, headers, body = nil
      status, headers, body = @app.call(env)
      [status, headers, body]
    end

    def logger
      @logger
    end

    def set_trace
      trace = TracePoint.new(:class, :call, :return) { |tp| logger.info "*** #{[tp.path.gsub(Rails.root.to_s, ''), tp.lineno, tp.event, tp.method_id]}" if tp.path.include?(Rails.root.to_s) }
      #trace = TracePoint.new(:call, :return) { |tp| logger.info "*** #{[tp.path.gsub(Rails.root.to_s, ''), tp.lineno, tp.event, tp.method_id]}" unless tp.path.incluyde?("/Users/thyago.barbosa/.rbenv/") }
      trace.enable
      yield
      trace.disable
    end
  end
end
