require 'logger'

module TextlabNLP
  module Logging
    def logger
      Logging.logger
    end

    # Global, memoized, lazy initialized instance of a logger
    def self.logger
      @logger ||= Logger.new(STDOUT)
    end
  end
end
