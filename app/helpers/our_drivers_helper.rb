module OurDriversHelper
  def driver_average_rating(driver)
    unless driver.blank?
      driver_reviews = driver.driver_reviews
    else
      driver_reviews = nil
    end
    driver_rating = 0
    unless driver_reviews.blank?
      driver_reviews.each do |driver_review|
        driver_rating += driver_review.rating
      end
    end
    if driver_rating > 0
      driver_rating = driver_rating/driver_reviews.size
    end
    inactive_driver_rating = 5 - driver_rating
    return driver_rating, inactive_driver_rating
  end
end
