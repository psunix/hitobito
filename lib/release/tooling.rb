# frozen_string_literal: true

#  Copyright (c) 2020-2023, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Release
  # preparatory help-tooling
  module Tooling
    private

    def suggested_next_version(current = current_version)
      incrementor =
        case current
        # 1.28.46 / 1.28.46.1
        when /\A\d+\.\d+\.\d+(\.\d+)?\z/ then ->(parts) { parts[0..-2] + [parts.last.succ] }
        end

      current.split('.').then { |parts| incrementor[parts] }.join('.')
    end

    def current_version
      `git tag | grep '^[0-9]' | sort -Vr | head -n 1`.chomp
    end

    def all_versions
      `git tag | grep '^[0-9]'`.chomp.split
    end

    def determine_version
      return @version unless @version.nil?

      ask('Next Version: ', suggested_next_version)
    end

    def new_version_message
      "Update production to #{@version}"
    end

    def with_env(env_hash)
      previous = ENV.select { |env_key| env_hash.keys.include? env_key }
      env_hash.each { |key, value| ENV[key] = value.to_s }

      result = yield

      previous.each { |key, value| ENV[key] = value }

      result
    end

    def cli
      @cli ||= begin
        require 'highline'
        HighLine.new
      rescue LoadError
        abort(<<~MESSAGE)
          Please install "highline" to unlock the interactivity of this script
        MESSAGE
      end
    end

    def colorize
      @colorize ||= begin
        require 'pastel'
        Pastel.new
      rescue LoadError
        abort(<<~MESSAGE)
          Please install "pastel" to unlock colorized output of this script
        MESSAGE
      end
    end
  end
end
