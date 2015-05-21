module Gobstones::Spec
  class ErrorMessageParser
    def remove_traceback (x)
      x.take_while { |str| not str.start_with? 'Traceback' }
    end

    def remove_line_specification(x)
      x.drop(3)
    end

    def remove_boom_line_specification(x)
      x.take_while { |str| not str.strip.start_with? 'En:' }
    end

    def parse(result)
      remove_boom_line_specification(remove_traceback(remove_line_specification(result.lines))).join.strip
    end
  end

  class Example
    attr_reader :gobstones_path

    def initialize(gobstones_path)
      @gobstones_path = gobstones_path
    end

    def start!(test_definition)
      @expected_final_board_gbb = test_definition[:final_board]
      @expected_final_board = Gobstones::GbbParser.new.from_string test_definition[:final_board]

      @html_output_file = Tempfile.new %w(gobstones.output .html)
      @actual_final_board_file = Tempfile.new %w(gobstones.output .gbb)
      @source_file = create_temp_file test_definition, :source, 'gbs'
      @initial_board_file = create_temp_file test_definition, :initial_board, 'gbb'

      "#{run_on_gobstones @source_file, @initial_board_file, @actual_final_board_file} 2>&1 &&" +
          "#{run_on_gobstones @source_file, @initial_board_file, @html_output_file}"
    end

    def result
      actual = Gobstones::GbbParser.new.from_string(@actual_final_board_file.read)

      if actual == @expected_final_board
        ["<div>#{@html_output_file.read}</div>", :passed]
      else
        initial_board = get_html_board @initial_board_file.open.read
        expected_board = get_html_board @expected_final_board_gbb

        output =
"<div>
  <b>Tablero inicial</b> #{initial_board}
  <b>Tablero final obtenido</b> #{@html_output_file.read}
  <b>Tablero final esperado</b> #{expected_board}
</div>"

        [output, :failed]
      end
    end


    def parse_error_message(result)
      ErrorMessageParser.new.parse(result)
    end

    def stop!
      [@html_output_file, @actual_final_board_file].each { |it| it.close }
      [@html_output_file, @actual_final_board_file, @source_file, @initial_board_file].each { |it| it.unlink }
    end

    private


    def run_on_gobstones(source_file, initial_board_file, final_board_file)
      "#{gobstones_path} #{source_file.path} --from #{initial_board_file.path} --to #{final_board_file.path}"
    end

    def create_temp_file(test_definition, attribute, extension)
      file = Tempfile.new %W(gobstones.#{attribute} .#{extension})
      file.write test_definition[attribute]
      file.close
      file
    end

    def get_html_board(gbb_representation)
      identity = Tempfile.new %w(gobstones.identity .gbs)
      identity.write 'program {}'
      identity.close

      board = Tempfile.new %w(gobstones.board .gbb)
      board.write gbb_representation
      board.close

      board_html = Tempfile.new %w(gobstones.board .html)

      %x"#{run_on_gobstones(identity, board, board_html)}"

      board_html.read
    end
  end

end
