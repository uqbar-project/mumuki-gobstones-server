require 'ostruct'

module StonesSpec
  class Example < OpenStruct
    include StonesSpec::WithTempfile
    include StonesSpec::WithCommandLine
    include StonesSpec::WithGbbHtmlRendering

    def initialize(subject, attributes)
      super attributes
      @title = attributes[:title]
      @subject = subject
    end

    def start!(source, precondition, postcondition)
      @postcondition = postcondition
      @precondition = precondition

      @source_file = write_tempfile @subject.test_program(source, precondition.arguments), Gobstones.source_code_extension

      @actual_final_board_file = Tempfile.new %w(gobstones.output .gbb)
      @initial_board_file = write_tempfile precondition.initial_board_gbb, 'gbb'
      @result, @status = run_command  "#{Gobstones.run(@source_file, @initial_board_file, @actual_final_board_file)} 2>&1"
    end

    def result
      initial_board_gbb = @initial_board_file.open.read

      if @status == :failed
        error_message = Gobstones.parse_error_message @result
        return [self.title, :failed, make_error_output(error_message, initial_board_gbb)]
      end

      @postcondition.validate(initial_board_gbb, @actual_final_board_file.read, @result)
    end

    def stop!
      [@actual_final_board_file, @initial_board_file].each { |it| it.unlink }
    end

    def title
      @title || default_title
    end

    private

    def default_title
      @subject.default_title @precondition.arguments
    end

    def make_error_output(error_message, initial_board_gbb)
      if Gobstones.syntax_error? error_message
        raise GobstonesSyntaxError, error_message
      end

      if Gobstones.runtime_error? error_message
        "#{get_html_board 'Tablero inicial', initial_board_gbb}\n#{error_message}"
      else
        error_message
      end
    end
  end

  class GobstonesSyntaxError < Exception
  end
end
