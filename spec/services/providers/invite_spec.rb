# frozen_string_literal: true

require "rails_helper"

RSpec.describe Providers::Invite do
  let(:company) { companies(:gogrow) }

  def invite(email: "ana@proveedor.com")
    described_class.call(name: "Ana Proveedora", email: email, company: company)
  end

  it "creates the user and the provider and sends the invitation" do
    expect { invite }.to have_enqueued_email(UserMailer, :invitation)

    user = User.find_by!(email: "ana@proveedor.com")
    expect(user.name).to eq("Ana Proveedora")
    expect(user).not_to be_verified
    expect(user.provider).to be_present
    expect(user.roles).to eq([ "provider" ])
    expect(OtpCode.pending?(user, :invitation)).to be(true)
  end

  it "leaves a password nobody knows until the provider chooses one" do
    user = invite

    expect(user.password_digest).to be_present
    expect(User.authenticate_by(email: user.email, password: "")).to be_nil
  end

  it "normalizes the email" do
    expect(invite(email: " ANA@Proveedor.com ").email).to eq("ana@proveedor.com")
  end

  it "resends to a provider that has not registered yet once the cooldown passes" do
    invite

    expect { invite }.not_to have_enqueued_mail(UserMailer, :invitation)

    travel 2.minutes do
      expect { invite }.to have_enqueued_email(UserMailer, :invitation)
    end
    expect(User.where(email: "ana@proveedor.com").count).to eq(1)
    expect(Provider.where(user: User.find_by(email: "ana@proveedor.com")).count).to eq(1)
  end

  it "refuses an email that already belongs to a registered provider" do
    expect { invite(email: users(:provider_user).email) }.to raise_error(described_class::EmailTaken)
  end

  it "refuses an email that belongs to an employee" do
    expect { invite(email: users(:one).email) }.to raise_error(described_class::EmailTaken)
  end

  it "does not leave a user behind when the email is invalid" do
    expect { invite(email: "no-es-un-mail") }.to raise_error(ActiveRecord::RecordInvalid)
    expect(User.where(email: "no-es-un-mail")).to be_empty
  end
end
