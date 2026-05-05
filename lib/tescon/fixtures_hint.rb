# frozen_string_literal: true

module Tescon
  # Formats FactoryBot usages as fixture YAML suggestions.
  class FixturesHint
    def self.format(results)
      new(results).format
    end

    def initialize(results)
      @results = Array(results)
      @fixture_names = Hash.new(0)
    end

    def format
      sections = results.filter_map { |result| section_for(result) }
      return "" if sections.empty?

      "#{sections.join("\n")}\n"
    end

    private

    attr_reader :results, :fixture_names

    def section_for(result)
      usages = result.factory_usages
      return if usages.empty?

      lines = ["# #{fixture_filename(result.source_file.path)}"]
      usages.each { |usage| lines.concat(fixture_lines_for(usage)) }
      lines.join("\n")
    end

    def fixture_filename(path)
      "#{File.basename(path, File.extname(path))}.yml"
    end

    def fixture_lines_for(usage)
      literal_attributes = usage.attributes.select(&:literal)
      dynamic_attributes = usage.attributes.reject(&:literal)
      fixture_name = fixture_name_for(usage)

      return ["#{fixture_name}: {}"] if literal_attributes.empty? && dynamic_attributes.empty?

      lines = ["#{fixture_name}:"]
      literal_attributes.each do |attribute|
        lines << "  #{attribute.name}: #{yaml_scalar(attribute.value)}"
      end
      dynamic_attributes.each do |attribute|
        lines << "  # TODO: #{attribute.name}: #{attribute.source}"
      end
      lines
    end

    def fixture_name_for(usage)
      factory_slug = slug(usage.factory_name)
      context_slugs = usage.context.map { |label| slug(label) }.reject(&:empty?)
      context_slugs = context_slugs.reject { |label| label == factory_slug }
      base = if context_slugs.empty?
               "#{source_slug(usage.source_file.path)}_l#{usage.line}_#{factory_slug}"
             else
               (context_slugs + [factory_slug]).join("_")
             end

      unique_fixture_name(base, usage.source_file.path)
    end

    def unique_fixture_name(base, path)
      key = [path, base]
      fixture_names[key] += 1
      return base if fixture_names[key] == 1

      "#{base}_#{fixture_names[key]}"
    end

    def source_slug(path)
      slug(File.basename(path, File.extname(path)))
    end

    def slug(value)
      value.to_s.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/\A_+|_+\z/, "")
    end

    def yaml_scalar(value)
      case value
      when String
        value.inspect
      when NilClass
        "null"
      else
        value.to_s
      end
    end
  end
end
