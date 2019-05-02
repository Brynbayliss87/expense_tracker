require_relative '../../../app/api'
require 'rack/test'

module ExpenseTracker

  RSpec.describe API do
    include Rack::Test::Methods

    def app
      API.new(ledger: ledger)
    end

    def parse_json(response)
      JSON.parse(response)
    end

    let(:ledger) { instance_double('ExpenseTracker::Ledger') }
    let(:expense) { { 'some' => 'data' } }

    before do
      allow(ledger).to receive(:record).with(expense).and_return(RecordResult.new(true, 417,nil))
    end

    describe 'POST /expenses' do
      context 'when the expense is properly recorded' do
        it 'returns the expense id' do
          post '/expenses', JSON.generate(expense)
          expect(parse_json(last_response.body)
).to include('expense_id' => 417)
        end

        it 'responds with a 200' do
          post '/expenses', JSON.generate(expense)
          expect(last_response.status).to eq(200)
        end
      end

      context 'when the expense fails validation' do
        let(:expense) { { "some" => "data" } }

        before do
          allow(ledger).to receive(:record).with(expense).and_return(RecordResult.new(false, 417, 'Expense incomplete'))
        end

        it 'returns an error message' do
          post '/expenses', JSON.generate(expense)
          expect(parse_json(last_response.body)).to include("error" => "Expense incomplete")
        end

        it 'responds with a 422' do
          post '/expenses', JSON.generate(expense)
          expect(last_response.status).to eq(422)
        end
      end
    end

    describe 'GET /expenses/:date' do
      context 'when expenses exist on the given date' do
        let(:date) { '2017-06-10' }
        let(:coffee) {
           { 'payee' => 'starbucks',
            'amount' => 5.75,
            'date' => '2017-06-10'
           }
        }

        before do
          allow(ledger).to receive(:expenses_on).with(date).and_return([coffee])
        end

        it 'returns the expense records as JSON' do
          get '/expenses/2017-06-10'
          expect(parse_json(last_response.body)).to include(coffee)
        end

        it 'responds with a 200 (OK)' do
          get '/expenses/2017-06-10'
          expect(last_response.status).to eq(200)
        end
      end

      context 'when there are no expenses on the given date' do

        let(:date) { '1969-12-31' }

        before do
          allow(ledger).to receive(:expenses_on).with(date).and_return([])
        end

        it 'returns an empty array as JSON' do
          get '/expenses/1969-12-31'
          expect(parse_json(last_response.body)).to eq([])
        end

        it 'responds with a 200 (OK)' do
          get '/expenses/1969-12-31'
          expect(last_response.status).to eq(200)
        end
      end
    end
  end
end
