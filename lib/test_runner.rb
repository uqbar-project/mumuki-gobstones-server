require 'mumukit'
require 'yaml'

class ErrorMessageParser
  def parse(result)
    remove_line_specification = lambda { |x| x.drop(3) }

    remove_traceback = lambda { |x|
      x.take_while { |str| not str.start_with? 'Traceback' }
    }

    remove_boom_line_specification = lambda { |x|
      x.take_while { |str| not str.strip.start_with? 'En:' }
    }

    remove_boom_line_specification[
        remove_traceback[
            remove_line_specification[
                result.lines
            ]
        ]
    ].join.strip
  end
end

class TestRunner
  def gobstones_path
    @config['gobstones_command']
  end

  def post_process_file(file, result, status)
    begin
      message = status == :passed ? '' : get_error_message(result)
      output = [message, status]

      output[2] = "<div>#{@output_file.read}</div>" if status == :passed

      output
    ensure
      @output_file.close(true)
    end
  end

  def get_error_message(result)
    ErrorMessageParser.new.parse(result)
  end

  def run_test_command(file)
    @output_file = Tempfile.new %w(gobstones.output .html)

    test_definition = YAML::load_file file.path

    source_file = create_temp_file test_definition, 'source', 'gbs'
    initial_board_file = create_temp_file test_definition, 'initial_board', 'gbb'

    "#{gobstones_path} #{source_file.path} --from #{initial_board_file.path} --to #{@output_file.path} 2>&1"
  end

  private

  def create_temp_file(run, attribute, extension)
    source_file = Tempfile.new %W(gobstones.#{attribute} .#{extension})
    source_file.write run[attribute]
    source_file.close
    source_file
  end
end