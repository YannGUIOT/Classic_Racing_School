class Order < ApplicationRecord
  after_create :fill_order, :empty_cart, :copy_to_spreadsheet, :order_send

  belongs_to :user
  has_many :order_items
  has_many :driving_courses, through: :order_items

  def total_price
    total = 0
    self.order_items.each do |order_item|
        total += order_item.driving_course.price
    end
    return total
  end

  private

  def order_send
    AdminMailer.order_confirmation_admin(self).deliver_now
    UserMailer.order_confirmation_user(self).deliver_now
  end

  def fill_order
    self.user.cart.cart_items.each do |cart_item|
      OrderItem.create(order_id: self.id, driving_course_id: cart_item.driving_course.id)
    end
  end

  def empty_cart
    self.user.cart.cart_items.destroy_all
  end

  def google_credentials
    {
      type: "service_account",
      project_id: "classic-racing-school",
      private_key_id: Rails.application.credentials.google[:private_key_id],
      private_key: Rails.application.credentials.google[:private_key],
      client_email: Rails.application.credentials.google[:client_email],
      client_id: Rails.application.credentials.google[:client_id],
      auth_uri: "https://accounts.google.com/o/oauth2/auth",
      token_uri: "https://oauth2.googleapis.com/token",
      auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
      client_x509_cert_url: "https://www.googleapis.com/robot/v1/metadata/x509/classic-racing-school%40classic-racing-school.iam.gserviceaccount.com"
    }.to_json
  end

  def copy_to_spreadsheet
    require "google_drive"
    session = GoogleDrive::Session.from_service_account_key(StringIO.new(google_credentials))
    ws = session.spreadsheet_by_key("1jDZCuEp2L9iE8v_BWdQIpZaxU-wwNX3ysJOy-7DX-8M").worksheets[0]

    # Gets content of A2 cell.
    p ws[2, 1]  #==> "hoge"

    # Changes content of cells.
    # Changes are not sent to the server until you call ws.save().
    row = 3 
    while ws[row, 1] != ""
      row += 1
    end
    self.order_items.each do |item|
      ws[row, 1] = "date"
      ws[row, 2] = "numéro de place"
      ws[row, 3] = "contact CRS"
      ws[row, 4] = item.driving_course.title
      ws[row, 5] = self.user.last_name
      ws[row, 6] = self.user.first_name
      ws[row, 7] = self.user.phone
      ws[row, 8] = self.user.email
      ws[row, 9] = "Pays"
      ws[row, 10] = ""
      ws[row, 11] = ""
      ws[row, 12] = ""
      ws[row, 13] = ""
      ws[row, 14] = ""
      ws[row, 15] = "En ligne"
      ws[row, 16] = "Paiement validé"
      ws[row, 17] = item.driving_course.price
      ws.save
      row = row + 1
    end

    # Dumps all cells.
    (1..ws.num_rows).each do |row|
      (1..ws.num_cols).each do |col|
        ws[row, col]
      end
    end

    # Yet another way to do so.
    p ws.rows  #==> [["fuga", ""], ["foo", "bar]]

    # Reloads the worksheet to get changes by other clients.
    ws.reload
  end

end
