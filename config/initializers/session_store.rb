# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_HTN_dashboard_session',
  :secret      => 'b21b80f1edd35ff6acb7670a6b5749a3a64ebef0825ddefff4535b0ad037e4a81e3b9470b6d24c64ae9c55243f763d8c02e70b720967e840860f034e10a3f062'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
