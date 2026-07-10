# frozen_string_literal: true

module Tescon
  module Trace
    # Converts absolute paths to project-relative paths for provenance YAML.
    module PathNormalizer
      module_function

      def relativize(path, root: Tescon::Trace.config.project_root)
        return path if path.nil? || path.empty? || path == "unknown"

        path_str = path.to_s
        root_str = File.expand_path(root.to_s)

        expanded = File.expand_path(path_str)
        if expanded.start_with?(root_str + File::SEPARATOR)
          expanded.delete_prefix(root_str + File::SEPARATOR)
        elsif expanded == root_str
          ""
        else
          path_str
        end
      end

      def relativize_caller(caller, root: Tescon::Trace.config.project_root)
        return caller if caller.nil? || caller.empty? || caller == "unknown"

        file_path, lineno = split_caller(caller)
        relative_path = relativize(file_path, root: root)
        lineno ? "#{relative_path}:#{lineno}" : relative_path
      end

      def relativize_spec_path(spec_path)
        relativize(spec_path).sub(/\.rb\z/, "")
      end

      def split_caller(caller)
        if caller =~ /\A(.+):(\d+)\z/
          [::Regexp.last_match(1), ::Regexp.last_match(2)]
        else
          [caller, nil]
        end
      end
      private_class_method :split_caller
    end
  end
end
