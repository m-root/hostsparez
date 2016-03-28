module JobsHelper
  def only_us_and_canada
    Carmen::Country.all.select { |c| %w{US CA}.include?(c.code) }
  end
end
