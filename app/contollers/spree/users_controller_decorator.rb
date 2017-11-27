Spree::UsersController.class_eval do

	def show
    @orders = @user.orders.complete.where(parent_id: nil).order('completed_at desc')
  end
end