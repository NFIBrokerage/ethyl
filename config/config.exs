import Config

config :chaps,
  terminal_options: [
    file_column_width: 60
  ],
  coverage_options: [
    treat_no_relevant_lines_as_covered: true,
    html_filter_fully_covered: true
  ]
