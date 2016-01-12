class UserController < ApplicationController
  def login
    if request.post?
      user = User.authenticate(params[:username],params[:password])
      if user
        User.current = user
        session[:user_id] = user.id
        redirect_to '/' and return 
      end
    end
    reset_session
  end

end
