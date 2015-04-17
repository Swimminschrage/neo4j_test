require 'spec_helper'
require 'fileutils'

describe 'Neo4jTest' do
  let(:test_directory) { 'tmp/test' }

  describe '::Server' do
    describe '#start_neo4j_server' do
      let(:server) { double(start: true, stop: true, to_s: 'DUMMY') }
      before(:each) do
        # Don't actually create/start a Neo4j server...
        allow(Neo4jTestServer).to receive(:server).and_return(server)
      end

      it 'is idempotent' do
        allow(Neo4jTestServer).to receive(:neo4j_running?).and_return(false, true, true)
        allow(Neo4jTestServer).to receive(:wait_for_server).and_return(true)

        expect(server).to receive(:start).once

        # Execute the method 3 times
        3.times do
          Neo4jTestServer::start_neo4j_server
        end
      end

      it 'raises an exception if it doesnt hear from neo4j' do
        allow(Neo4jTestServer).to receive(:neo4j_running?).and_return(false)

        # Set the timeout to a more reasonable time for this test
        Neo4jTestServer::neo4j_startup_timeout = 4 #seconds

        expect{ Neo4jTestServer::start_neo4j_server }.to raise_error(Neo4jTestServer::TimeoutError)
      end
    end
  end

  describe '::Installer' do
    before(:each) do
      FileUtils.mkdir_p test_directory
    end

    after(:each) do
      FileUtils.remove_dir(test_directory) if File.exist? test_directory
    end

    describe '#file_name' do
      it 'return the correct filename for windows' do
        allow(OS::Underlying).to receive(:windows?) { true }

        expect(Neo4jTest::Installer.file_name).to eq 'neo4j.zip'
      end

      it 'returns the correct filename for unix' do
        allow(OS::Underlying).to receive(:windows?) { false }

        expect(Neo4jTest::Installer.file_name).to eq 'neo4j-unix.tar.gz'
      end

      it 'returns the correct filename given an edition' do
        allow(OS::Underlying).to receive(:windows?) { true }

        expect(Neo4jTest::Installer.file_name('myedition')).to eq 'myedition-neo4j.zip'
      end
    end

    describe '#download_neo4j' do

      it 'downloads the correct file' do
        allow(Neo4jTest::Installer).to receive(:request_url).and_return('Test data')
        allow(Neo4jTest::Installer).to receive(:download_to).and_return(File.join(test_directory, 'test.txt'))

        Neo4jTest::Installer.download_neo4j 'community-2.2.0'
        expect(File.exist?('tmp/test')).to be true
      end
    end

    describe '#download_neo4j_unless_exists' do
      it 'downloads the correct file the first time' do
        allow(Neo4jTest::Installer).to receive(:request_url).and_return('Test data')
        allow(Neo4jTest::Installer).to receive(:download_to).and_return(File.join(test_directory, 'test.txt'))

        Neo4jTest::Installer.download_neo4j 'community-2.2.0'
        expect(File.exist?('tmp/test')).to be true
      end

      it 'doesnt download on subsequent tries' do
        allow(Neo4jTest::Installer).to receive(:request_url).and_return('Test data')
        allow(Neo4jTest::Installer).to receive(:download_to).and_return(File.join(test_directory, 'test.txt'))

        Neo4jTest::Installer.download_neo4j_unless_exists 'community-2.2.0'
        expect(File.exist?('tmp/test')).to be true

        expect(Neo4jTest::Installer).to_not receive(:download_neo4j)
        Neo4jTest::Installer.download_neo4j_unless_exists 'community-2.2.0'
        expect(File.exist?('tmp/test')).to be true
      end
    end

    describe '#download_to' do

      shared_examples 'a valid download location' do
        shared_examples 'a downloadable edition' do
          let(:pwd) { '/Users/testuser/.rvm/gems/ruby-2.2.1@neo4j_test/gems/neo4j-4.1.5/'}

          it 'returns the correct save to location' do
            allow(OS::Underlying).to receive(:windows?).and_return is_windows?
            allow(Neo4jTest::Installer).to receive(:here).and_return("#{pwd}/test.rb")
            expect(Neo4jTest::Installer.download_to(edition)).to eq expected_download_to
          end
        end

        context 'given community-2.2.0 edition' do
          let(:edition) { 'community-2.2.0' }
          let(:expected_download_to) { File.join pwd, "#{edition}-neo4j#{ext}" }

          it_behaves_like 'a downloadable edition'
        end

        context 'without an edition' do
          let(:edition) { '' }
          let(:expected_download_to) { File.join pwd, "neo4j#{ext}" }

          it_behaves_like 'a downloadable edition'
        end
      end

      context 'on a Unix machine' do
        let(:ext) { '-unix.tar.gz' }
        let(:is_windows?) { false }

        it_behaves_like 'a valid download location'
      end

      context 'on a Windows machine' do
        let(:ext) { '.zip'}
        let(:is_windows?) { true }
        it_behaves_like 'a valid download location'
      end
    end
  end
end
