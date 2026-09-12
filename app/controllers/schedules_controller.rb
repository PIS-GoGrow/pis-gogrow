# frozen_string_literal: true

class SchedulesController < InertiaController
    before_action :authenticate_provider

    def create
        provider = Current.user.provider
        date = Date.iso8601(params.require(:date))
        items = params.require(:items)

        if date < Date.current
            redirect_to schedules_path,
                        inertia: { errors: { date: [ "No se puede publicar un menú para una fecha pasada" ] } }
            return
        end

        if date > maximum_publish_date
            redirect_to schedules_path,
                        inertia: { errors: { date: [ "La fecha está fuera del rango permitido de publicación" ] } }
            return
        end
                    
        unless valid_initial_stock?(items)
        redirect_to schedules_path,
                    inertia: { errors: { amount: [ "El stock inicial debe ser mayor a 0" ] } }
        return
        end

        if published_date?(provider, date)
            redirect_to schedules_path,
                        inertia: { errors: { date: [ "Ya existe un menú publicado para esta fecha" ] } }
            return
        end

        Schedule.transaction do 
        items.each do |item|
            menu = provider.menus.find(item.require(:menu_id)) 

            menu.schedules.create!(
            date: date,
            amount: item.require(:amount)
            )
        end
        end

        redirect_to schedules_path
    end

    def valid_initial_stock?(items)
        items.all? do |item|
        amount = Integer(item.require(:amount), exception: false)
        amount.present? && amount.positive?
        end
    end

    def published_date?(provider, date)
        provider.menus
                .joins(:schedules)
                .where(schedules: { date: date })
                .exists?
    end

    def maximum_publish_date
        Date.current.end_of_week(:monday) + 1.week
    end

end
