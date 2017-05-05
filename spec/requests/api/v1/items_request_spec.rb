require 'rails_helper'

describe "Items API" do
  it "sends a list of items" do
    merchant = Merchant.create!(name: 'Lady Jane')
    items = create_list(:item, 3, merchant: merchant)

    get '/api/v1/items'

    expect(response).to be_success

    items = JSON.parse(response.body)

    expect(items.count).to eq(3)
  end

  it "can get one item by its id" do
    merchant = Merchant.create!(name: 'Lady Jane')
    item = create_list(:item, 3, merchant: merchant).first
    id = item.id

    get "/api/v1/items/#{id}"

    item = JSON.parse(response.body)

    expect(response).to be_success
    expect(item["id"]).to eq(id)
  end

  it "returns a collection of associated invoice items" do
    merchant = create(:merchant)
    customer = create(:customer)
    invoice = create(:invoice, merchant: merchant, customer: customer)
    item1 = create(:item, merchant: merchant)
    item2 = create(:item, merchant: merchant)
    invoice_items1 = create_list(:invoice_item, 3, item: item1, invoice: invoice)
    invoice_items2 = create_list(:invoice_item, 3, item: item2, invoice: invoice)
    id = item1.id

    get "/api/v1/items/#{id}/invoice_items"

    invoice_items = JSON.parse(response.body)

    expect(response).to be_success
    expect(invoice_items.count).to eq(invoice_items1.count)
    expect(invoice_items.first["id"]).to eq(invoice_items1.first.id)
  end

  it "returns the associated merchant" do
    merchant1 = create(:merchant)
    merchant2 = create(:merchant)
    items = create_list(:item, 3, merchant: merchant1)
    id = items.first.id
    get "/api/v1/items/#{id}/merchant"
    merchant = JSON.parse(response.body)

    expect(response).to be_success
    expect(items.first.merchant).to eq(merchant1)
    expect(items.first.merchant).to_not eq(merchant2)
  end

  it "returns an items best day" do
    customer1 = create(:customer)
    merchant1 = create(:merchant, name: 'Billy Bobs Bacon')
    item1 = create(:item, merchant: merchant1)
    invoice1 = create(:invoice, created_at: "2000-03-27 14:53:59 UTC", merchant: merchant1, customer: customer1)
    invoice2 = create(:invoice, created_at: "2001-03-27 14:53:59 UTC", merchant: merchant1, customer: customer1)
    invoice3 = create(:invoice, created_at: "2002-03-27 14:53:59 UTC", merchant: merchant1, customer: customer1)
    invoice4 = create(:invoice, created_at: "2003-03-27 14:53:59 UTC", merchant: merchant1, customer: customer1)
    InvoiceItem.create(invoice: invoice1, item: item1, quantity: 4)
    InvoiceItem.create(invoice: invoice2, item: item1, quantity: 4)
    InvoiceItem.create(invoice: invoice3, item: item1, quantity: 1)
    InvoiceItem.create(invoice: invoice4, item: item1, quantity: 4)
    create(:transaction, invoice: invoice1, result: 'success')
    create(:transaction, invoice: invoice2, result: 'success')
    create(:transaction, invoice: invoice3, result: 'success')
    create(:transaction, invoice: invoice4, result: 'failed')
    id = item1.id

    get "/api/v1/items/#{id}/best_day"

    endpoint_day = JSON.parse(response.body)

    expect(endpoint_day["best_day"]).to eq("2001-03-27T14:53:59.000Z")
  end

  it "returns top x items ranked by revenue" do
    customer = create(:customer)
    merchant = create(:merchant)
    invoice1 = create(:invoice, merchant: merchant, customer: customer)
    invoice2 = create(:invoice, merchant: merchant, customer: customer)
    invoice3 = create(:invoice, merchant: merchant, customer: customer)
    invoice4 = create(:invoice, merchant: merchant, customer: customer)
    item1 = create(:item, merchant: merchant)
    item2 = create(:item, merchant: merchant)
    item3 = create(:item, merchant: merchant)
    item4 = create(:item, merchant: merchant)
    InvoiceItem.create!(invoice: invoice1, item: item1, quantity: 5, unit_price: 345)
    InvoiceItem.create!(invoice: invoice2, item: item2, quantity: 10, unit_price: 345)
    InvoiceItem.create!(invoice: invoice3, item: item3, quantity: 45, unit_price: 345)
    InvoiceItem.create!(invoice: invoice4, item: item4, quantity: 2, unit_price: 345)
    create(:transaction, invoice: invoice1)
    create(:transaction, invoice: invoice2)
    create(:transaction, invoice: invoice3)
    create(:transaction, invoice: invoice4)

    get "/api/v1/items/most_revenue?quantity=5"

    item_endpoint = JSON.parse(response.body)
    expect(response).to be_success
    expect(item_endpoint.count).to eq(4)
    expect(item_endpoint.first['name']).to eq(item3.name)
    expect(item_endpoint.second['name']).to eq(item2.name)
    expect(item_endpoint.third['name']).to eq(item1.name)


  end
end
