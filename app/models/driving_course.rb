class DrivingCourse < ApplicationRecord
    has_many :cart_items
    has_many :order_items
    has_many :carts, through: :cart_items
    has_many :orders, through: :order_items

    validates :title, presence: true, length: {in: 3..300, message: "Le Titre du Stage doit avoir une longueur comprise entre 3 and 300 caractères"}
    validates :description, presence: true, length: {in: 10..2000, message: "La Description du Stage doit avoir une longueur comprise entre 10 and 1000 caractères"}
    validates :date, presence: true, if: :in_the_futur
    validates :quantity, presence: true, numericality: {greater_than: 0, message: "La Quantité doit être positive"}
    validates :price, presence: true, numericality: {greater_than: 0, message: "Le Prix doit être positif"}
    validates :image_url, presence: true

    def in_the_futur
        errors.add(:date, "Vous ne pouvez pas créer un Stage de Pilotage dans le passé") unless date > Date.now
    end
end
