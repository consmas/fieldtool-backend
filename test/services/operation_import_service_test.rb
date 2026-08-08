require "test_helper"

class OperationImportServiceTest < ActiveSupport::TestCase
  test "imports csv rows into operation records" do
    Tempfile.create(["operations", ".csv"]) do |file|
      file.write("Date,Trip ID,Truck ID,Driver Name,Expected Revenue,Status,Remarks\n")
      file.write("2026-08-01,TRIP-001,GT-1295-26,Bright Foekpe,3750,Operational,Loaded\n")
      file.write("2026-08-02,TRIP-002,GT-1296-26,Marthin Nuwordu,4164,Pending,Waiting\n")
      file.rewind

      service = OperationImportService.new(
        file_path: file.path,
        file_name: "operations.csv",
        record_type: "trip",
        reporting_month: "Aug 2026"
      )

      assert_difference("OperationRecord.count", 2) do
        service.import!
      end

      record = OperationRecord.order(:created_at).last
      assert_equal "TRIP-002", record.trip_id
      assert_equal "GT-1296-26", record.truck_id
      assert_equal "Marthin Nuwordu", record.driver_name
      assert_equal "Pending", record.status
    end
  end

  test "imports historical trip backfill rows and skips non-trip rows" do
    Tempfile.create(["historical_operations", ".csv"]) do |file|
      file.write("Date,Customer Name,Waybill No.,Destination,No. of Stops,Additional km Travelled,Fuel Cost Per Litre*,Base Fee,Additional Fee*,Total Fee\n")
      file.write("2026-02-02,Mac Bennet Company (Returning),6524,Kumasi,1,0,0,3750.00,0,3750.00\n")
      file.write("2026-02-06,Downtime (Repairs),n/a,n/a,0,0,0,0,0,0\n")
      file.write("TOTAL,,,,,,,,,\n")
      file.rewind

      service = OperationImportService.new(
        file_path: file.path,
        file_name: "historical.csv",
        record_type: "trip",
        reporting_month: "Feb 2026"
      )

      assert_difference("OperationRecord.count", 1) do
        service.import!
      end

      record = OperationRecord.order(:created_at).last
      assert_equal "2026-02-02", record.entry_date.to_s
      assert_equal "6524", record.waybill_no
      assert_equal "Kumasi", record.destination
      assert_equal 3750.0, record.expected_revenue.to_f
      assert_equal "Completed", record.status
      assert_match(/Mac Bennet/, record.notes.to_s)
    end
  end

  test "imports workbook style invoice rows and skips holiday and weekend rows" do
    Tempfile.create(["invoice_rows", ".csv"]) do |file|
      file.write("Date,Customer Name,Waybill No.,Destination,No. of Stops,Additional km Travelled,Fuel Cost Per Litre*,Base Fee,Additional Fee,Total Fee\n")
      file.write("2026-05-01,Holiday,n/a,n/a,n/a,0,16.1,0,0,0\n")
      file.write("2026-05-02,Weekend,n/a,n/a,n/a,0,16.1,0,0,0\n")
      file.write("2026-05-04,De Simone Ltd.,1176 / 1177,Accra,2,12,16.1,4000,193.2,4193.2\n")
      file.rewind

      service = OperationImportService.new(
        file_path: file.path,
        file_name: "invoice.csv",
        record_type: "trip",
        reporting_month: "May 2026"
      )

      assert_difference("OperationRecord.count", 1) do
        service.import!
      end

      record = OperationRecord.order(:created_at).last
      assert_equal "2026-05-04", record.entry_date.to_s
      assert_equal "1176 / 1177", record.waybill_no
      assert_equal "Accra", record.destination
      assert_equal 4193.2, record.expected_revenue.to_f
      assert_equal "Completed", record.status
      assert_match(/De Simone/, record.notes.to_s)
    end
  end
end
