# frozen_string_literal: true

require 'yaml'
require 'ostruct'
require 'markdown-tables'

solutions_path = './Solutions'
explainers_path = './Explainers'

hackerrank_solutions_path = File.join(solutions_path, 'Hackerrank')
hackerrank_explainers_path = File.join(explainers_path, 'Hackerrank')
hackerrank_challenge_base_path = 'https://www.hackerrank.com/challenges/'

codewars_solutions_path = File.join(solutions_path, 'Codewars')
codewars_explainers_path = File.join(explainers_path, 'Codewars')
codewars_challenge_base_path = 'https://www.codewars.com/kata/'

LABELS =
  %w[Challenges Solutions Explainers].freeze

sanitize_string =
  ->(s) { s.each_char.select { |c| c =~ /[a-z|A-Z|0-9]/ }.join }

challenge_to_markdown =
  lambda { |challenge|
    [
      "[#{challenge.title}](#{challenge.challenge_url})",
      "[Solution](#{challenge.solution})",
      "[Explainer](#{challenge.explainer})"
    ]
  }

challenges_yaml =
  YAML.safe_load(File.read('challenges.yml'))

HACKERRANK_FORMATTED =
  challenges_yaml['hackerrank']
  .map do |challenge_raw|
    challenge = OpenStruct.new(
      slug: challenge_raw['slug'],
      title: challenge_raw['title'],
      solution: challenge_raw['solution'],
      explainer: challenge_raw['explainer'],
      challenge_url: challenge_raw['challenge_url']
    )

    # Ensure `title` Is Present
    unless challenge.title
      pp challenge
      throw '`title` Is Required'
    end

    # Generate Default Slug
    challenge.slug = challenge.title.downcase.gsub(' ', '-') unless challenge.slug

    # Generate Default Challenge URL
    challenge.challenge_url = hackerrank_challenge_base_path + challenge.slug unless challenge.challenge_url

    # Generate Default Solution Path
    solution_basename = sanitize_string.call(challenge.title)
    challenge.solution = File.join(hackerrank_solutions_path, solution_basename)

    # Generate Default Explainer Path
    challenge.explainer =
      if challenge.explainer
        File.join(hackerrank_explainers_path, solution_basename)
      else
        hackerrank_explainers_path
      end

    challenge
  end
  .sort { |a, b| a.title <=> b.title } # Sort By Challenge Title
  .freeze # Immutable

HACKERRANK_MARKDOWN =
  HACKERRANK_FORMATTED.map { |challenge| challenge_to_markdown.call(challenge) }

HACKERRANK_TABLE =
  MarkdownTables.make_table(LABELS, HACKERRANK_MARKDOWN, is_rows: true, align: %w[l l l])

CODEWARS_FORMATTED =
  challenges_yaml['codewars']
  .map do |challenge_raw|
    challenge = OpenStruct.new(
      slug: challenge_raw['slug'],
      title: challenge_raw['title'],
      solution: challenge_raw['solution'],
      explainer: challenge_raw['explainer'],
      challenge_url: challenge_raw['challenge_url']
    )

    # Ensure `title` Is Present
    unless challenge.title
      pp challenge
      throw '`title` Is Required'
    end

    # Ensure `slug` Is Present
    unless challenge.slug
      pp challenge
      throw '`slug` Is Required For Codewars Challenges'
    end

    # Generate Default Challenge URL
    challenge.challenge_url = codewars_challenge_base_path + challenge.slug unless challenge.challenge_url

    # Generate Default Solution Path
    solution_basename = sanitize_string.call(challenge.title)
    challenge.solution = File.join(codewars_solutions_path, solution_basename)

    # Generate Default Explainer Path
    challenge.explainer =
      if challenge.explainer
        File.join(codewars_explainers_path, solution_basename)
      else
        codewars_explainers_path
      end

    challenge
  end
  .sort { |a, b| a.title <=> b.title } # Sort By Challenge Title
  .freeze # Immutable

CODEWARS_MARKDOWN =
  CODEWARS_FORMATTED.map { |challenge| challenge_to_markdown.call(challenge) }

CODEWARS_TABLE =
  MarkdownTables.make_table(LABELS, CODEWARS_MARKDOWN, is_rows: true, align: %w[l l l])

# Generate Final README.md

readme_template =
  File.read('README_TEMPLATE.md')

readme =
  readme_template
  .gsub('%hackerrank_challenges%', HACKERRANK_TABLE)
  .gsub('%codewars_challenges%',   CODEWARS_TABLE)

File.open('README.md', 'w') { |file| file.puts readme }