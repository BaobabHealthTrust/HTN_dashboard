class HomeController < ApplicationController
  def index
    patient_present_concept = ConceptName.find_by_name('Patient present').concept
    yes_concept = ConceptName.find_by_name('Yes').concept

    screen_age = GlobalProperty.find_by_property('htn.screening.age.threshold').property_value.to_i
    screen_sbp_treashold = GlobalProperty.find_by_property('htn.systolic.threshold').property_value.to_i
    screen_dbp_treashold = GlobalProperty.find_by_property('htn.diastolic.threshold').property_value.to_i
    
     
    total_patients = Person.count(:all, :joins => "INNER JOIN encounter e ON e.patient_id = person.person_id
      INNER JOIN obs ON e.encounter_id = obs.encounter_id AND obs.concept_id = #{patient_present_concept.id} 
      AND obs.value_coded = #{yes_concept.id}",:conditions => ["age(birthdate,now(),date(person.date_created),birthdate_estimated) >= ?
      AND obs_datetime BETWEEN (?) AND (?)",screen_age,Date.today.strftime('%Y-%m-%d 00:00:00'),
      Date.today.strftime('%Y-%m-%d 23:59:59')],:group =>  "person.person_id").count

    
    sbp = ConceptName.find_by_name('Systolic blood pressure').concept
    dbp = ConceptName.find_by_name('Diastolic blood pressure').concept
    total_screened = Observation.count(:all,:joins => "INNER JOIN person p ON p.person_id = obs.person_id 
      AND age(birthdate,now(),date(p.date_created),birthdate_estimated) >= #{screen_age}",
      :conditions => ["concept_id IN(?) AND obs_datetime BETWEEN ? AND ?",[sbp.id,dbp.id],
      Date.today.strftime('%Y-%m-%d 00:00:00'), Date.today.strftime('%Y-%m-%d 23:59:59')],:group => 'obs.person_id').count
    
    uncontrolled_sql =<<EOF
SELECT t.person_id,t.value_numeric sbp,t2.value_numeric dbp,t.obs_datetime,t2.obs_datetime FROM obs t 
INNER JOIN obs t2 ON t.person_id = t2.person_id
AND t.concept_id = #{sbp.id} AND t2.concept_id = #{dbp.id}
INNER JOIN person p ON p.person_id = t.person_id AND age(birthdate,now(),date(p.date_created),birthdate_estimated) >= #{screen_age}
WHERE t.obs_datetime BETWEEN '#{Date.today.strftime('%Y-%m-%d 00:00:00')}' AND '#{Date.today.strftime('%Y-%m-%d 23:59:59')}'
AND t2.obs_datetime BETWEEN '#{Date.today.strftime('%Y-%m-%d 00:00:00')}' AND '#{Date.today.strftime('%Y-%m-%d 23:59:59')}'
AND t.obs_datetime = (select max(obs_datetime) from obs where concept_id = t.concept_id AND person_id = t.person_id
AND obs_datetime BETWEEN '#{Date.today.strftime('%Y-%m-%d 00:00:00')}' AND '#{Date.today.strftime('%Y-%m-%d 23:59:59')}')
AND t2.obs_datetime = (select max(obs_datetime) from obs where concept_id = t2.concept_id AND person_id = t2.person_id
AND obs_datetime BETWEEN '#{Date.today.strftime('%Y-%m-%d 00:00:00')}' AND '#{Date.today.strftime('%Y-%m-%d 23:59:59')}')
GROUP BY t.person_id HAVING sbp > #{screen_sbp_treashold} OR dbp > #{screen_dbp_treashold};
EOF


    controlled_sql =<<EOF
SELECT t.person_id,t.value_numeric sbp,t2.value_numeric dbp,t.obs_datetime,t2.obs_datetime FROM obs t 
INNER JOIN obs t2 ON t.person_id = t2.person_id
AND t.concept_id = #{sbp.id} AND t2.concept_id = #{dbp.id}
INNER JOIN person p ON p.person_id = t.person_id AND age(birthdate,now(),date(p.date_created),birthdate_estimated) >= #{screen_age}
WHERE t.obs_datetime BETWEEN '#{Date.today.strftime('%Y-%m-%d 00:00:00')}' AND '#{Date.today.strftime('%Y-%m-%d 23:59:59')}'
AND t2.obs_datetime BETWEEN '#{Date.today.strftime('%Y-%m-%d 00:00:00')}' AND '#{Date.today.strftime('%Y-%m-%d 23:59:59')}'
AND t.obs_datetime = (select max(obs_datetime) from obs where concept_id = t.concept_id AND person_id = t.person_id
AND obs_datetime BETWEEN '#{Date.today.strftime('%Y-%m-%d 00:00:00')}' AND '#{Date.today.strftime('%Y-%m-%d 23:59:59')}')
AND t2.obs_datetime = (select max(obs_datetime) from obs where concept_id = t2.concept_id AND person_id = t2.person_id
AND obs_datetime BETWEEN '#{Date.today.strftime('%Y-%m-%d 00:00:00')}' AND '#{Date.today.strftime('%Y-%m-%d 23:59:59')}')
GROUP BY t.person_id HAVING sbp <= #{screen_sbp_treashold} AND dbp <= #{screen_dbp_treashold};
EOF

    uncontrolled = Observation.find_by_sql(uncontrolled_sql).count
    controlled = Observation.find_by_sql(controlled_sql).count
    
    @chart_data_total = { :day_one => {:day => '',:count => 0}, :day_two =>  {:day => '',:count => 0}, 
      :day_three =>  {:day => '',:count => 0},:day_four =>  {:day => '',:count => 0}, 
      :day_five => {:day => '',:count => 0}, :day_six =>  {:day => '',:count => 0}, 
      :day_seven =>  {:day => '',:count => 0} }

    (1.upto(7)).each do |num|
    date = Date.today - num.day

    total = Person.count(:all, :joins => "INNER JOIN encounter e ON e.patient_id = person.person_id
      INNER JOIN obs ON e.encounter_id = obs.encounter_id AND obs.concept_id = #{patient_present_concept.id} 
      AND obs.value_coded = #{yes_concept.id}",:conditions => ["age(birthdate,date('#{date.to_s}'),date(person.date_created),birthdate_estimated) >= ?
      AND obs_datetime BETWEEN (?) AND (?)",screen_age,date.strftime('%Y-%m-%d 00:00:00'),
      date.strftime('%Y-%m-%d 23:59:59')],:group =>  "person.person_id").count
      case num
        when 1
          @chart_data_total[:day_one][:count] = total 
          @chart_data_total[:day_one][:day] = date
        when 2
          @chart_data_total[:day_two][:count] = total 
          @chart_data_total[:day_two][:day] = date
        when 3
          @chart_data_total[:day_three][:count] = total 
          @chart_data_total[:day_three][:day] = date
        when 4
          @chart_data_total[:day_four][:count] = total 
          @chart_data_total[:day_four][:day] = date
        when 5
          @chart_data_total[:day_five][:count] = total 
          @chart_data_total[:day_five][:day] = date
        when 6
          @chart_data_total[:day_six][:count] = total 
          @chart_data_total[:day_six][:day] = date
        when 7
          @chart_data_total[:day_seven][:count] = total 
          @chart_data_total[:day_seven][:day] = date
      end
    end


    @chart_data_total_screened = { :day_one => {:day => '',:count => 0}, :day_two =>  {:day => '',:count => 0}, 
      :day_three =>  {:day => '',:count => 0},:day_four =>  {:day => '',:count => 0}, 
      :day_five => {:day => '',:count => 0}, :day_six =>  {:day => '',:count => 0}, 
      :day_seven =>  {:day => '',:count => 0} }

    (1.upto(7)).each do |num|
    date = Date.today - num.day

    total = Observation.count(:all, :joins => "INNER JOIN person p ON p.person_id = obs.person_id 
      AND age(birthdate,now(),date(p.date_created),birthdate_estimated) >= #{screen_age}",
      :conditions => ["concept_id IN(?) AND obs_datetime BETWEEN ? AND ?",[sbp.id,dbp.id],
      date.strftime('%Y-%m-%d 00:00:00'), date.strftime('%Y-%m-%d 23:59:59')],:group => 'obs.person_id').count
      case num
        when 1
          @chart_data_total_screened[:day_one][:count] = total 
          @chart_data_total_screened[:day_one][:day] = date
        when 2
          @chart_data_total_screened[:day_two][:count] = total 
          @chart_data_total_screened[:day_two][:day] = date
        when 3
          @chart_data_total_screened[:day_three][:count] = total 
          @chart_data_total_screened[:day_three][:day] = date
        when 4
          @chart_data_total_screened[:day_four][:count] = total 
          @chart_data_total_screened[:day_four][:day] = date
        when 5
          @chart_data_total_screened[:day_five][:count] = total 
          @chart_data_total_screened[:day_five][:day] = date
        when 6
          @chart_data_total_screened[:day_six][:count] = total 
          @chart_data_total_screened[:day_six][:day] = date
        when 7
          @chart_data_total_screened[:day_seven][:count] = total 
          @chart_data_total_screened[:day_seven][:day] = date
      end
    end


    @indicators = {:passed_reception => total_patients, :screened => total_screened, 
      :uncontrolled => uncontrolled, :controlled => controlled}
  end

end
