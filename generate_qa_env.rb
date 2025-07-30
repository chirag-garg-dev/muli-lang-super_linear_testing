#!/usr/bin/env ruby

require 'tty-prompt'
require 'erb'
require 'pg'
require 'fileutils'
require 'securerandom'

class CampusCreator
  attr_accessor :db_host, :ams_db_name, :db_user, :db_password, :prompt, :corp
  attr_accessor :conn, :url_postfix
  attr_accessor :campus_lower, :campus_upper
  attr_accessor :template_db, :user_type

  def initialize
    @db_host = 'masterk-pnc-db.cwisbi42xice.eu-central-1.rds.amazonaws.com'
    @ams_db_name = 'ams'
    @db_user = 'pinc'
    @db_password = 'pincpinc'
    @url_postfix = 'masterk'
    @prompt = TTY::Prompt.new
    # @conn = PG.connect( dbname: ams_db_name, host: db_host, user: db_user, password: db_password)
  end

  def intro
    puts "This script helps you configure a new YMS running on the k8s cluster"
    puts "   with database at #{db_host}"
  end

  def get_yms_branch_name
    branch_name = prompt.ask "what is the name of the branch you want to test?" do |q|
      q.required true
      q.modify   :up
    end
    puts "You have answered: #{branch_name}"
  end

  def get_template_name
    @template_db = prompt.select("Choose your template", %w(abs-por kft-win nke-el1 win-r61 ))
    puts "You have answered: #{template_db}"
    @template_db
  end

  def get_user_type_name
    user_types = [
    "Guest",
    "Information Only",
    "Gatekeeper",
    "Supervisor",
    "System Administrator",
    "Root",
    "Site Admin",
    "Driver",
    "Specialist",
    "Standard",
    "Shipping/Receiving",
    "Kiosk",
    "Customer",
    "Logistics Admin",
    ]
    @user_type = prompt.select("Choose your template", user_types)
    puts "You have answered: #{@user_type}"
    @user_type
  end

  def generate_new_campus_code
    corp_code = 'pnc'
    extension = SecureRandom.alphanumeric(3).downcase
    campus_code = "#{corp_code}#{extension}"
    @campus_lower = "#{corp_code.downcase}-#{extension.downcase}"
    @campus_upper = "#{corp_code.upcase}#{extension.upcase}"
    @campus_lower
  end

  # If you want to undo this, use the following SQL
  # ams=> delete from user_campus_settings where campus_id = (select id from campuses where code = 'PNCBAT');
  # ams=> delete from campuses where code = 'PNCBAT';
  #
  def create_ams_sql
    url = "https://#{campus_lower}-#{url_postfix}.pincsolutions.com"
    sql = %Q| insert into campuses
        (name, code, url_address, active, created_at, updated_at, corporation_id, has_pinc)
      values
       ('#{campus_lower}', '#{campus_upper}', '#{url}', true, now(), now(), '#{corp['id']}', true);
    |
    # puts sql
    res = conn.exec( sql )
    # insert into sites

    sql = %Q| insert into user_campus_settings
                (user_id, campus_id, yh_role_id, timezone, created_at, updated_at)
                (select
                  users.id, campuses.id, 6, 'Monrovia', now(), now() from users, campuses
                    where users.corporation_id = #{corp['id']} and code = '#{campus_upper}');
    |
    # puts sql
    res = conn.exec( sql )
  end

  def done_with_step?(msg)
    tf_done = 'n'
    while tf_done != true do
      tf_done = prompt.yes? msg
      puts "You have answered: #{tf_done}"
    end
  end

  def create_db
    create_db = "create database -T #{template_db} yms_#{campus_lower.gsub(/-/, '_')}"
    cmd =  "psql -U pinc -h #{db_host} postgres -c '#{create_db}'"
    puts "run this command to create the database:"
    puts "    #{cmd}"
  end

  def create_terraform_file
    puts "Creating terraform file for things we need to stand up the YMS"
    file_name = "yms_#{campus_lower}.tf"
    [
      'infrastructure/yms_config.tf'
    ].each do |config_name|
      template = ERB.new File.read("templates/#{config_name}.erb"), nil, "%"
      res = template.result(binding)
      File.write("infrastructure/#{file_name}", res)
      # puts res
    end
    puts "Review file #{file_name}, and run 'terraform apply'."
  end

  def create_deploy_dir
    FileUtils.mkdir_p "deploys/yms-#{campus_lower}"
  end

  def create_dns_routes
    manifests = [
      'yms_cname.json'
    ]
    manifests.each do |manifest_name|
      template = ERB.new File.read("templates/dns/#{manifest_name}.erb"), nil, "%"
      res = template.result(binding)
      File.write("cname_upsert_#{campus_lower}.json", res)
    end
    cmd = "aws route53 change-resource-record-sets --hosted-zone-id Z18VLYZVAE1LIJ --change-batch file://cname_upsert_#{campus_lower}.json"
    puts "If you have your AWS keys/region set, you can run this command to set the AWS Route53 routes"
    puts "    #{cmd}"
  end

end

url_postfix = 'masterk'
prompt = TTY::Prompt.new
campus_creator = CampusCreator.new
campus_creator.intro

branch_name = campus_creator.get_yms_branch_name
db_template_to_use = campus_creator.get_template_name

user_type = campus_creator.get_user_type_name

# generate random campus-code
partial_campus_code = campus_creator.generate_new_campus_code
puts "Full campus code (upper/lower): #{campus_creator.campus_upper}/#{campus_creator.campus_lower}"

# 1. create the database
campus_creator.create_db
campus_creator.done_with_step? "have you created the database ok?"

# 2. create the terraform file for the campus
#campus_creator.create_terraform_file

# 3. provision AWS with the SNS/SQS for the campus
# campus_creator.done_with_step? "have you finished running terraform and it ran ok?"


# 4. create helm chart from options
# puts "Created a helm chart for new yms. Running it now."
campus_creator.done_with_step? "I ran the helm deploy. Do want to check the pods?"

# ...
# ...

# 8. add details about new campus to AMS
# campus_creator.create_ams_sql

# 9. Add routing to AWS Route53
# campus_creator.create_dns_routes

# puts "Default data has default site code - you need to set it to the correct one for your YMS. Run this SQL:"
# puts "    psql -U pinc -h dw-db.cwisbi42xice.eu-central-1.rds.amazonaws.com yms_#{campus_lower.gsub(/-/, '_')}"
# puts "    update sites set code = '#{campus_upper}YRD';"
# campus_creator.done_with_step? "have you updated the default site code?"

# puts "Now that the site code is fixed, you can run:"
# puts "   - yms-resque-schedules: tell resque what needs to be scheduled"

# campus_creator.done_with_step? "have you completed the deploys?"
# puts "Your site is live!"
