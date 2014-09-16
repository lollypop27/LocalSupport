require 'spec_helper'

describe "organisations/edit.html.erb" do
  before(:each) do
    @organisation = assign(:organisation, stub_model(Organisation,
                                                     :new_record? => false, :donation_info => "http://www.friendly.com/donate"
    ))
  end

  it "renders the edit organisation form" do
    view.lookup_context.prefixes = %w[organisations application]
    render

    rendered.should have_selector("form", :action => organisation_path(@organisation), :method => "post") do |form|
    end
  end

  it "renders the edit organisation form with tooltips" do
    view.lookup_context.prefixes = %w[organisations application]

    render

    hash = {'organisation_name' => 'Enter a unique name',
            'organisation_address'  => 'Enter a complete address',
            'organisation_postcode' => 'Make sure post code is accurate',
            'organisation_email' => 'Make sure email is correct',
            'organisation_description' => "Enter a full description here\. When an individual searches this database all words in this description will be searched\.",
            'organisation_website' => 'Make sure url is correct',
            'organisation_telephone' => 'Make sure phone number is correct',
            'organisation_admin_email_to_add' => "Please enter the details of individuals from your organisation you would like to give permission to update your entry\. E-mail addresses entered here will not be made public\.",
            'organisation_donation_info' => 'Please enter a website here either to the fundraising page on your website or to an online donation site.',
            'organisation_publish_email' => 'To make your email address visible to the public check this box',
            'organisation_publish_telephone' => 'To make your telephone number visible to the public check this box',
            'organisation_publish_address' => 'To make your full address visible to the public check this box'
    }
    hash.each do |label,tooltip|
      rendered.should have_xpath("//tr/td[contains(.,#{label})]/../td[@data-toggle=\"tooltip\"][@title=\"#{tooltip}\"]")
    end
  end


it "renders the donation_info url in edit form" do
  render
  rendered.should have_field :organisation_donation_info,
                             :with => "http://www.friendly.com/donate"
end

it "renders a form field to add an administrator email" do
  render
  rendered.should have_field :organisation_admin_email_to_add
end

it "renders a checkbox to make address public" do
  render
  rendered.should have_selector('input', :id => 'organisation_publish_address', :type => 'checkbox')
end

it "renders a checkbox to make email public" do
  render
  rendered.should have_selector('input', :id => 'organisation_publish_email', :type => 'checkbox')
end

it "renders a checkbox to make phone number public" do
  render
  rendered.should have_selector('input', :id => 'organisation_publish_phone', :type => 'checkbox')
end

it 'renders an update button with Anglicized spelling of Organisation' do
  render
  rendered.should have_selector("input", :type => "submit", :value => "Update Organisation")
end
#todo: move this into proper integration test to avoid the errors mocking
#out being coupled with rails
it 'renders errors without prefatory error message' do
  errors = double("errors", :any? => true, :count => 1, :full_messages => ["Sample error"], :[] => double("somethingRailsExpects", :any? => false))
  org = stub_model(Organisation)
  org.stub(:errors => errors)
  @organisation = assign(:organisation, org)
  render
  render.should have_content("Sample error")
  render.should_not have_content("1 error prohibited this organisation from being saved:")
end
end
