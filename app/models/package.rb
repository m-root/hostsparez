class Package < ActiveRecord::Base
  attr_accessible :name, :weight, :description, :amount, :user_id, :basic_fee, :cost_per_mile, :min_fare
  validates_presence_of :name, :weight, :description, :user_id
  validates :weight, :numericality => true
  validates :amount, :numericality => true
  validates :basic_fee, :numericality => true
  validates :cost_per_mile, :numericality => true
  validates :min_fare, :numericality => true

  belongs_to :user


  def self.packages_json()
    Package.all.map{|package| {:id => package.id, :name => package.name, :weight => package.weight, :description => package.description, :amount => package.amount, :basic_fee => package.basic_fee,:cost_per_mile => package.cost_per_mile,:min_fare => package.min_fare}}
  end

end
