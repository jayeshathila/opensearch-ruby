# SPDX-License-Identifier: Apache-2.0
#
# The OpenSearch Contributors require contributions made to
# this file be licensed under the Apache-2.0 license or a
# compatible open source license.
#
# Modifications Copyright OpenSearch Contributors. See
# GitHub history for details.
#
# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require 'spec_helper'

describe OpenSearch::Transport::Transport::Base do
  context 'when a host is printed in a logged message' do
    shared_examples_for 'a redacted string' do
      let(:client) do
        OpenSearch::Transport::Client.new(arguments)
      end

      let(:logger) do
        double('logger', error?: true, error: '')
      end

      it 'does not include the password in the logged string' do
        expect(logger).not_to receive(:error).with(/secret_password/)

        expect {
          client.perform_request('GET', '_cluster/stats')
        }.to raise_exception(Faraday::ConnectionFailed)
      end

      it 'replaces the password with the string \'REDACTED\'' do
        expect(logger).to receive(:error).with(/REDACTED/)
        expect {
          client.perform_request('GET', '_cluster/stats')
        }.to raise_exception(Faraday::ConnectionFailed)
      end
    end

    context 'when the user and password are provided as separate arguments' do
      let(:arguments) do
        {
          hosts: 'fake',
          logger: logger,
          password: 'secret_password',
          user: 'test'
        }
      end

      it_behaves_like 'a redacted string'
    end

    context 'when the user and password are provided in the string URI' do
      let(:arguments) do
        {
          hosts: 'https://test:secret_password@fake_local_opensearch',
          logger: logger
        }
      end

      if jruby?
        let(:client) { OpenSearch::Transport::Client.new(arguments) }
        let(:logger) { double('logger', fatal?: true, fatal: '') }

        it 'does not include the password in the logged string' do
          expect(logger).not_to receive(:fatal).with(/secret_password/)

          expect {
            client.perform_request('GET', '_cluster/stats')
          }.to raise_exception(Faraday::SSLError)
        end

        it 'replaces the password with the string \'REDACTED\'' do
          expect(logger).to receive(:fatal).with(/REDACTED/)
          expect {
            client.perform_request('GET', '_cluster/stats')
          }.to raise_exception(Faraday::SSLError)
        end
      else
        it_behaves_like 'a redacted string'
      end
    end

    context 'when the user and password are provided in the URI object' do
      let(:arguments) do
        {
          hosts: URI.parse('https://test:secret_password@fake_local_opensearch'),
          logger: logger
        }
      end
      if jruby?
        let(:client) { OpenSearch::Transport::Client.new(arguments) }
        let(:logger) { double('logger', fatal?: true, fatal: '') }

        it 'does not include the password in the logged string' do
          expect(logger).not_to receive(:fatal).with(/secret_password/)

          expect {
            client.perform_request('GET', '_cluster/stats')
          }.to raise_exception(Faraday::SSLError)
        end

        it 'replaces the password with the string \'REDACTED\'' do
          expect(logger).to receive(:fatal).with(/REDACTED/)
          expect {
            client.perform_request('GET', '_cluster/stats')
          }.to raise_exception(Faraday::SSLError)
        end
      else
        it_behaves_like 'a redacted string'
      end
    end
  end

  context 'when reload_on_failure is true and and hosts are unreachable' do
    let(:client) do
      OpenSearch::Transport::Client.new(arguments)
    end

    let(:arguments) do
      {
        hosts: ['http://unavailable:9200', 'http://unavailable:9201'],
        reload_on_failure: true,
        sniffer_timeout: 5
      }
    end

    it 'raises an exception' do
      expect { client.perform_request('GET', '/') }.to raise_exception(Faraday::ConnectionFailed)
    end
  end

  context 'when the client has `retry_on_failure` set to an integer' do
    let(:client) do
      OpenSearch::Transport::Client.new(arguments)
    end

    let(:arguments) do
      {
        hosts: ['http://unavailable:9200', 'http://unavailable:9201'],
        retry_on_failure: 2
      }
    end

    context 'when `perform_request` is called without a `retry_on_failure` option value' do
      before do
        expect(client.transport).to receive(:get_connection).exactly(3).times.and_call_original
      end

      it 'uses the client `retry_on_failure` value' do
        expect {
          client.transport.perform_request('GET', '/info')
        }.to raise_exception(Faraday::ConnectionFailed)
      end
    end

    context 'when `perform_request` is called with a `retry_on_status` option value' do
      before do
        expect(client.transport).to receive(:__raise_transport_error).exactly(6).times.and_call_original
      end

      let(:arguments) do
        {
          hosts: OPENSEARCH_HOSTS,
          retry_on_status: ['404']
        }
      end

      it 'retries on 404 status the specified number of max_retries' do
        expect do
          client.transport.perform_request('GET', 'myindex/mydoc/1?routing=FOOBARBAZ', {}, nil, nil, retry_on_failure: 5)
        end.to raise_exception(OpenSearch::Transport::Transport::Errors::NotFound)
      end
    end

    context 'when `perform_request` is called with a `retry_on_failure` option value' do
      before do
        expect(client.transport).to receive(:get_connection).exactly(6).times.and_call_original
      end

      it 'uses the option `retry_on_failure` value' do
        expect do
          client.transport.perform_request('GET', '/info', {}, nil, nil, retry_on_failure: 5)
        end.to raise_exception(Faraday::ConnectionFailed)
      end
    end
  end

  context 'when the client has `retry_on_failure` set to true' do
    let(:client) do
      OpenSearch::Transport::Client.new(arguments)
    end

    let(:arguments) do
      {
          hosts: ['http://unavailable:9200', 'http://unavailable:9201'],
          retry_on_failure: true
      }
    end

    context 'when `perform_request` is called without a `retry_on_failure` option value' do
      before do
        expect(client.transport).to receive(:get_connection).exactly(4).times.and_call_original
      end

      it 'uses the default `MAX_RETRIES` value' do
        expect {
          client.transport.perform_request('GET', '/info')
        }.to raise_exception(Faraday::ConnectionFailed)
      end
    end

    context 'when `perform_request` is called with a `retry_on_failure` option value' do
      before do
        expect(client.transport).to receive(:get_connection).exactly(6).times.and_call_original
      end

      it 'uses the option `retry_on_failure` value' do
        expect {
          client.transport.perform_request('GET', '/info', {}, nil, nil, retry_on_failure: 5)
        }.to raise_exception(Faraday::ConnectionFailed)
      end
    end
  end

  context 'when the client has `retry_on_failure` set to false' do
    let(:client) do
      OpenSearch::Transport::Client.new(arguments)
    end

    let(:arguments) do
      {
          hosts: ['http://unavailable:9200', 'http://unavailable:9201'],
          retry_on_failure: false
      }
    end

    context 'when `perform_request` is called without a `retry_on_failure` option value' do
      before do
        expect(client.transport).to receive(:get_connection).once.and_call_original
      end

      it 'does not retry' do
        expect {
          client.transport.perform_request('GET', '/info')
        }.to raise_exception(Faraday::ConnectionFailed)
      end
    end

    context 'when `perform_request` is called with a `retry_on_failure` option value' do

      before do
        expect(client.transport).to receive(:get_connection).exactly(6).times.and_call_original
      end

      it 'uses the option `retry_on_failure` value' do
        expect {
          client.transport.perform_request('GET', '/info', {}, nil, nil, retry_on_failure: 5)
        }.to raise_exception(Faraday::ConnectionFailed)
      end
    end
  end

  context 'when the client has no `retry_on_failure` set' do
    let(:client) do
      OpenSearch::Transport::Client.new(arguments)
    end

    let(:arguments) do
      { hosts: ['http://unavailable:9200', 'http://unavailable:9201'] }
    end

    context 'when `perform_request` is called without a `retry_on_failure` option value' do
      before do
        expect(client.transport).to receive(:get_connection).exactly(1).times.and_call_original
      end

      it 'does not retry' do
        expect do
          client.transport.perform_request('GET', '/info')
        end.to raise_exception(Faraday::ConnectionFailed)
      end
    end

    context 'when `perform_request` is called with a `retry_on_failure` option value' do
      before do
        expect(client.transport).to receive(:get_connection).exactly(6).times.and_call_original
      end

      it 'uses the option `retry_on_failure` value' do
        expect do
          client.transport.perform_request('GET', '/info', {}, nil, nil, retry_on_failure: 5)
        end.to raise_exception(Faraday::ConnectionFailed)
      end
    end
  end
end
