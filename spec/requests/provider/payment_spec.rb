  it "lets the provider open the receipt of their payment" do
    user, payment = setup_submitted_payment
    sign_in(user, role: :provider)

    get receipt_provider_payment_path(payment)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("image/png")
  end

  it "does not let another provider open the receipt" do
    _user, payment = setup_submitted_payment
    other = create_provider("other-provider@gmail.com")
    sign_in(other.user, role: :provider)

    get receipt_provider_payment_path(payment)

    expect(response).to have_http_status(:not_found)
  end