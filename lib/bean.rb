class PatientBean 

 attr_accessor :given_name, :middle_name, :family_name, :gender, :birthdate, 
               :cell_phone_number, :office_phone_number, :home_phone_number, 
               :old_identification_number, :patient_id, :age, :visit_type,:skipped_vitals

	def initialize(name)
		@name = name
	end
end
