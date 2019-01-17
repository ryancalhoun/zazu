require 'zazu'
require 'fileutils'
require 'rspec'
require 'webmock/rspec'

describe Zazu do
  let(:name) { 'zazu-test-command' }
  subject { described_class.new name, logger: Logger.new(IO::NULL) }

  after do
    FileUtils.rm_f subject.path
  end

  describe 'fetch' do
    context 'skip' do
      before do
        File.write subject.path, 'hello'
      end
      it 'returns false' do
        expect(subject.fetch).to be false
      end
    end
    context 'download' do
      let(:url) { 'http://example.com/file' }
      let(:contents) { 'file contents' }
      before do
        stub_request(:get, url).to_return(status: 200, body: contents)
      end
      context 'no block' do
        it 'returns true' do
          expect(subject.fetch url: url).to be true
          expect(File.read subject.path).to be == contents
        end
      end

      context 'with block' do
        it 'returns true' do
          expect(subject.fetch {|os,arch| url }).to be true
          expect(File.read subject.path).to be == contents
        end
      end

      context 'redirect' do
        let(:first_url) { 'http://example.com/fancy_file_path' }
        before do
          stub_request(:get, first_url).to_return(status: 301, headers: {Location: url})
        end
        it 'returns true' do
          expect(subject.fetch url: first_url).to be true
          expect(File.read subject.path).to be == contents
        end
      end

      context 'error' do
        before do
          stub_request(:get, url).to_return(status: 404)
        end
        it 'raises' do
          expect { subject.fetch url: url }.to raise_error Zazu::DownloadError
        end
      end
    end
  end

  describe 'run' do
    context 'success' do
      before do
        File.write subject.path, "#!/bin/bash\necho apple\necho banana\n"
        FileUtils.chmod 0755, subject.path
      end
      it 'runs it' do
        expect(subject.run).to be true
      end

      it 'calls the block' do
        expect {|b| subject.run &b }.to yield_successive_args 'apple', 'banana'
      end

      it 'calls the block with showed' do
        expect {|b| subject.run show: /ppl/, &b }.to yield_successive_args 'apple'
      end

      it 'calls the block without hidden' do
        expect {|b| subject.run hide: /ppl/, &b }.to yield_successive_args 'banana'
      end
    end
    context 'error' do
      before do
        File.write subject.path, "#!/bin/bash\nexit 42\n"
        FileUtils.chmod 0755, subject.path
      end
      it 'raises' do
        expect { subject.run }.to raise_error Zazu::RunError
      end
    end
  end
end
