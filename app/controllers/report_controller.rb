class ReportController < ApplicationController
  def patients_not_screened
  end

  def get_patients_screened_outside_threshold
    start_date = params[:start_date].to_date
    end_date = params[:end_date].to_date

    screen_age = GlobalProperty.find_by_property('htn.screening.age.threshold').property_value.to_i
    screen_sbp_treashold = GlobalProperty.find_by_property('htn.systolic.threshold').property_value.to_i
    screen_dbp_treashold = GlobalProperty.find_by_property('htn.diastolic.threshold').property_value.to_i
    
    sbp = ConceptName.find_by_name('Systolic blood pressure').concept
    dbp = ConceptName.find_by_name('Diastolic blood pressure').concept
    total_screened = Person.find(:all,:joins => "INNER JOIN obs ON obs.person_id = person.person_id 
      AND age(birthdate,now(),date(person.date_created),birthdate_estimated) < #{screen_age}",
      :conditions => ["concept_id IN(?) AND obs_datetime BETWEEN ? AND ?",[sbp.id,dbp.id],
      start_date.strftime('%Y-%m-%d 00:00:00'), end_date.strftime('%Y-%m-%d 23:59:59')],
      :select => "person.person_id, obs.obs_datetime", :group => "person.person_id, date(obs_datetime)")

    render :text => get_patients(total_screened).to_json and return
  end

  def get_patients_not_screened
    start_date = params[:start_date].to_date
    end_date = params[:end_date].to_date

    patient_present_concept = ConceptName.find_by_name('Patient present').concept
    yes_concept = ConceptName.find_by_name('Yes').concept

    screen_age = GlobalProperty.find_by_property('htn.screening.age.threshold').property_value.to_i
    screen_sbp_treashold = GlobalProperty.find_by_property('htn.systolic.threshold').property_value.to_i
    screen_dbp_treashold = GlobalProperty.find_by_property('htn.diastolic.threshold').property_value.to_i
    
     
    total_patients = Person.find(:all, :joins => "INNER JOIN encounter e ON e.patient_id = person.person_id
      INNER JOIN obs ON e.encounter_id = obs.encounter_id AND obs.concept_id = #{patient_present_concept.id} 
      AND obs.value_coded = #{yes_concept.id}",:conditions => ["age(birthdate,now(),date(person.date_created),birthdate_estimated) >= ?
      AND obs_datetime BETWEEN (?) AND (?)",screen_age,start_date.strftime('%Y-%m-%d 00:00:00'),
      end_date.strftime('%Y-%m-%d 23:59:59')], :select => "person.person_id, obs.obs_datetime",
      :group => "person.person_id, date(obs_datetime)")

    
    sbp = ConceptName.find_by_name('Systolic blood pressure').concept
    dbp = ConceptName.find_by_name('Diastolic blood pressure').concept
    total_screened = Person.find(:all,:joins => "INNER JOIN obs ON obs.person_id = person.person_id 
      AND age(birthdate,now(),date(person.date_created),birthdate_estimated) >= #{screen_age}",
      :conditions => ["concept_id IN(?) AND obs_datetime BETWEEN ? AND ?",[sbp.id,dbp.id],
      start_date.strftime('%Y-%m-%d 00:00:00'), end_date.strftime('%Y-%m-%d 23:59:59')],
      :select => "person.person_id, obs.obs_datetime",:group => "person.person_id, date(obs_datetime)")

    patients = (total_patients - total_screened)
    render :text => get_patients(patients).to_json and return
  end

  private

  def get_patients(records)
    results = []
    encounter_type = EncounterType.find_by_name('Vitals')
    (records || []).each do |rec|
      person = Person.find(rec.person_id)
      date = rec.obs_datetime.to_date
      names = person.names.last rescue []
      first_name = names.given_name rescue ""
      last_name = names.family_name rescue ""

      patient_obj = PatientBean.new('')
      patient_obj.given_name = first_name
      patient_obj.family_name = last_name 
      patient_obj.birthdate = person.birthdate
      patient_obj.age = person.age(date)
      patient_obj.gender = person.gender
      patient_obj.patient_id = get_patient_identifier(person.patient)
      patient_obj.visit_type = date.to_time.strftime('%H:%M:%S') == '00:00:01' ? 'Retrospective' : 'Realtime'
      patient_obj.vitals_present = Observation.find(:first, :conditions =>["obs_datetime BETWEEN ? AND ? 
          AND encounter_type = ?",date.strftime('%Y-%m-%d 00:00:00'),date.strftime('%Y-%m-%d 23:59:59'),
          encounter_type],:joins =>"INNER JOIN encounter e ON e.encounter_id = obs.encounter_id 
          AND person_id = #{person.id}").blank? != true
      results << patient_obj 
    end

    return results
  end

  def get_patient_identifier(patient, identifier_type = 'National ID')
    patient_identifier_type_id = PatientIdentifierType.find_by_name(identifier_type).patient_identifier_type_id 
    patient_identifier = PatientIdentifier.find(:first, :select => "identifier",
      :conditions  =>["patient_id = ? and identifier_type = ?", patient.id, patient_identifier_type_id],
      :order => "date_created DESC" ).identifier rescue nil
    return patient_identifier
  end


end
