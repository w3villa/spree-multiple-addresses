Spree::OrdersController.class_eval do

	after_filter :update_child_order, only: [:populate]
	after_filter :empty_child_order, only: [:empty]
  after_filter :update_child_order_state, only: [:update]
  after_filter :change_child_order_state_to_cart, only: [:edit]

	def populate
    @order    = current_order(create_order_if_necessary: true)
    @variant  = Spree::Variant.find(params[:variant_id])
    @quantity = params[:quantity].to_i
    @options  = params[:options] || {}

    # 2,147,483,647 is crazy. See issue #2695.
    if @quantity.between?(1, 2_147_483_647)
      begin
        @order.contents.add(@variant, @quantity, @options)
      rescue ActiveRecord::RecordInvalid => e
        error = e.record.errors.full_messages.join(", ")
      end
    else
      error = Spree.t(:please_enter_reasonable_quantity)
    end

    if error
      flash[:error] = error
      redirect_back_or_default(spree.root_path)
    else
      respond_with(@order) do |format|
        format.html { redirect_to :back }
      end
    end
  end 

  private

  	def update_child_order
  		if params[:recipient] == "Me"
  			recipient = params[:recipient]
  		elsif params[:recipient] == "Recipient"
  			recipient = params[:recipient_name].present? ? params[:recipient_name] : "Me"
      else
        recipient = params[:recipient]
  		end
  		if @order.children_orders.present?
  			@child_order =  @order.children_orders.find_by_recipient_name(recipient)
  			if @child_order.present?
  				@child_order.contents.add(@variant, @quantity, @options)
  			else
  				@child_order = Spree::Order.create(parent_id: @order.id, recipient_name: recipient, email: "child_order@example.com")
  				@child_order.contents.add(@variant, @quantity, @options)
  			end
  		else
  			@child_order = Spree::Order.create(parent_id: @order.id, recipient_name: recipient, email: "child_order@example.com")
  			@child_order.contents.add(@variant, @quantity, @options)
  		end
  	end

  	def empty_child_order
  		if @order.children_orders.present?
  			@order.children_orders.each do |child_order|
  				child_order.destroy
  			end
  		end
  	end


    def update_child_order_state
      if params.has_key?(:checkout)
        @order.children_orders.each do |child_order|
          child_order.next if child_order.cart?
        end
      else
        @parent_order = @order.parent_order
        @parent_order.empty!
        @parent_order.children_orders.each do |child_order|
          if child_order.line_items.present?
            child_order.line_items.each do |line_item|
              @variant = line_item.variant
              @quantity = line_item.quantity
              @options  =  {}
              @parent_order.contents.add(@variant, @quantity, @options)
            end
          else
            child_order.destroy!
          end
        end
      end
    end

    def change_child_order_state_to_cart
      @order.children_orders.each do |child_order|
        unless child_order.cart?
          child_order.update_attributes(state: "cart")
        end
      end
    end

    def assign_order_with_lock
      if params[:order_id].present?
        @order = Spree::Order.find(params[:order_id])
      else
        @order = current_order(lock: true)
      end
      unless @order
        flash[:error] = Spree.t(:order_not_found)
        redirect_to root_path and return
      end
    end
end
