class Person < ActiveRecord::Base
  set_table_name "person"
  set_primary_key "person_id"
  include Openmrs

  cattr_accessor :session_datetime
  cattr_accessor :migrated_datetime
  cattr_accessor :migrated_creator
  cattr_accessor :migrated_location

  has_one :patient, :foreign_key => :patient_id, :dependent => :destroy, :conditions => {:voided => 0}
  has_many :names, :class_name => 'PersonName', :foreign_key => :person_id, :dependent => :destroy, :order => 'person_name.preferred DESC', :conditions => {:voided => 0}
  has_many :addresses, :class_name => 'PersonAddress', :foreign_key => :person_id, :dependent => :destroy, :order => 'person_address.preferred DESC', :conditions => {:voided => 0}
  has_many :relationships, :class_name => 'Relationship', :foreign_key => :person_a, :conditions => {:voided => 0}
  has_many :person_attributes, :class_name => 'PersonAttribute', :foreign_key => :person_id, :conditions => {:voided => 0}
  has_many :observations, :class_name => 'Observation', :foreign_key => :person_id, :dependent => :destroy, :conditions => {:voided => 0} do
    def find_by_concept_name(name)
      concept_name = ConceptName.find_by_name(name)
      find(:all, :conditions => ['concept_id = ?', concept_name.concept_id]) rescue []
    end
  end

  def after_void(reason = nil)
    self.patient.void(reason) rescue nil
    self.names.each{|row| row.void(reason) }
    self.addresses.each{|row| row.void(reason) }
    self.relationships.each{|row| row.void(reason) }
    self.person_attributes.each{|row| row.void(reason) }
    # We are going to rely on patient => encounter => obs to void those
  end

  def age(today = Date.today)
    return nil if self.birthdate.nil?

    # This code which better accounts for leap years
    patient_age = (today.year - self.birthdate.year) + ((today.month - self.birthdate.month) + ((today.day - self.birthdate.day) < 0 ? -1 : 0) < 0 ? -1 : 0)

    # If the birthdate was estimated this year, we round up the age, that way if
    # it is March and the patient says they are 25, they stay 25 (not become 24)
    birth_date=self.birthdate
    estimate=self.birthdate_estimated
    patient_age += (estimate && birth_date.month == 7 && birth_date.day == 1  &&
        today.month < birth_date.month && self.date_created.year == today.year) ? 1 : 0
  end

  def age_in_months(today = Date.today)
    years = (today.year - self.birthdate.year)
    months = (today.month - self.birthdate.month)
    (years * 12) + months
  end

end
