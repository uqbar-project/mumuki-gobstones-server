module StonesSpec
  module Postcondition
    def self.from(example, check_head_position, show_initial_board)
      example.final_board ?
          FinalBoardPostcondition.new(example, check_head_position, show_initial_board) :
          ReturnPostcondition.new(example)
    end
  end

  class FinalBoardPostcondition
    include StonesSpec::WithTempfile
    include StonesSpec::WithGbbHtmlRendering

    attr_reader :example, :check_head_position, :show_initial_board

    def initialize(example, check_head_position, show_initial_board)
      @example = example
      @check_head_position = check_head_position
      @show_initial_board = show_initial_board
    end

    def validate(initial_board_gbb, actual_final_board_gbb, _actual_return)
      if matches_with_expected_board? Stones::Gbb.read actual_final_board_gbb
        passed_result initial_board_gbb, actual_final_board_gbb
      else
        failed_result initial_board_gbb, example.final_board, actual_final_board_gbb
      end
    end

    private

    def failed_result(initial_board_gbb, expected_board_gbb, actual_board_gbb)
      boards = [
        ['Tablero final esperado', expected_board_gbb],
        ['Tablero final obtenido', actual_board_gbb]
      ]

      boards.unshift ['Tablero inicial', initial_board_gbb] if show_initial_board

      make_result boards, :failed
    end

    def passed_result(initial_board_gbb, actual_board_gbb)
      boards = [
        ['Tablero final', actual_board_gbb]
      ]

      boards.unshift ['Tablero inicial', initial_board_gbb] if show_initial_board

      make_result boards, :passed
    end

    def make_result(gbb_boards, status)
      boards = gbb_boards.map { |gbb_with_caption| get_html_board *gbb_with_caption, example.gobstones_command }.join("\n")
      output = "<div>#{boards}</div>"
      [with_header(example.title), output, status]
    end

    def matches_with_expected_board?(actual_board)
      if check_head_position
        actual_board == final_board
      else
        actual_board.cells_equal? final_board
      end
    end

    def final_board
      Stones::Gbb.read example.final_board
    end
  end

  class ReturnPostcondition
    include StonesSpec::WithGbbHtmlRendering

    attr_reader :example

    def initialize(example)
      @example = example
    end

    def validate(_initial_board_gbb, _actual_final_board_gbb, actual_return)
      normalized_actual_return = actual_return.strip

      if normalized_actual_return == return_value
        make_result(:passed)
      else
        make_result(:failed, "Se esperaba <b>#{return_value}</b> pero se obtuvo <b>#{normalized_actual_return}</b>")
      end
    end

    private

    def make_result(status, output='')
      [with_header("#{example.title} -> #{return_value}"), output, status]
    end

    def return_value
      example.return.to_s
    end
  end
end
