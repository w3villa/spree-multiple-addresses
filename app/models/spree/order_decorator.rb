module Spree
	Order.class_eval do
		# after_update :update_parent_line_items
		# ********************* Association *****************************************
		belongs_to :parent_order, class_name: "Spree::Order", foreign_key: :parent_id
		has_many :children_orders, class_name: "Spree::Order", foreign_key: :parent_id

		# ********************* Remove Confirm Step *********************************
		remove_checkout_step :confirm 
		# ********************* Methods *********************************************

		def get_recipients
			recipient_arr = ['Me', 'Recipient']
			if children_orders.present?
				recipient_arr.push(children_orders.collect(&:recipient_name))
			end
			recipient_arr = recipient_arr.flatten
			recipient_arr = recipient_arr.uniq
			return recipient_arr
		end

		def children_shipment_sum
			children_orders.collect{|child_order| child_order.shipments.to_a.sum(&:cost)}.sum.to_f
		end

		def update_parent_line_items
			if self.parent_id == nil
				@order = self
			else
				@order = self.parent_order
			end
			@order.empty!

			@order.children_orders.each do |child_order|
				if child_order.line_items.present?
					if child_order.line_items.count == 1 &&  child_order.line_items.first.quantity == 0
						child_order.destroy!
					else
						child_order.line_items.each do |line_item|
							@variant = line_item.variant
							@quantity = line_item.quantity
							@options  =  {}
							@order.contents.add(@variant, @quantity, @options)
						end
					end
				else
					child_order.destroy!
				end
			end

		end
		
	end
end