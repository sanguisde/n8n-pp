import Foundation

// MARK: - XLSX Writer
// Generates a valid .xlsx (Office Open XML) file in pure Swift.
// Uses ZIP stored entries (no compression) – no external dependencies needed.

final class XLSXWriter {

    static let shared = XLSXWriter()
    private init() {}

    // MARK: - Public API

    var exportURL: URL {
        URL.applicationSupportDirectory.appending(path: "TimeAudit-Log.xlsx")
    }

    /// Regenerate the xlsx from all entries and write to Application Support.
    @discardableResult
    func export(entries: [TimeEntry]) -> Bool {
        let files = buildXMLFiles(entries: entries)
        let zipData = buildZIP(files: files)
        do {
            try FileManager.default.createDirectory(
                at: URL.applicationSupportDirectory,
                withIntermediateDirectories: true
            )
            try zipData.write(to: exportURL)
            return true
        } catch {
            return false
        }
    }

    // MARK: - ZIP (Stored / Method 0 – no compression)

    private func buildZIP(files: [(name: String, data: Data)]) -> Data {
        struct Entry {
            let nameBytes: Data
            let fileBytes: Data
            let crc: UInt32
            let size: UInt32
        }

        let entries = files.map { name, data in
            Entry(nameBytes: name.data(using: .utf8)!,
                  fileBytes: data,
                  crc: Self.crc32(data),
                  size: UInt32(data.count))
        }

        let (dosDate, dosTime) = Self.dosDateTime()
        var zip = Data()
        var offsets: [UInt32] = []

        // Local file headers + data
        for entry in entries {
            offsets.append(UInt32(zip.count))
            zip.appendLE(UInt32(0x04034b50))        // local file header sig
            zip.appendLE(UInt16(20))                // version needed
            zip.appendLE(UInt16(0))                 // flags
            zip.appendLE(UInt16(0))                 // compression: stored
            zip.appendLE(dosTime)
            zip.appendLE(dosDate)
            zip.appendLE(entry.crc)
            zip.appendLE(entry.size)                // compressed size
            zip.appendLE(entry.size)                // uncompressed size
            zip.appendLE(UInt16(entry.nameBytes.count))
            zip.appendLE(UInt16(0))                 // extra field length
            zip.append(entry.nameBytes)
            zip.append(entry.fileBytes)
        }

        let cdOffset = UInt32(zip.count)
        var cd = Data()

        // Central directory records
        for (i, entry) in entries.enumerated() {
            cd.appendLE(UInt32(0x02014b50))         // central dir sig
            cd.appendLE(UInt16(20))                 // version made by
            cd.appendLE(UInt16(20))                 // version needed
            cd.appendLE(UInt16(0))                  // flags
            cd.appendLE(UInt16(0))                  // compression: stored
            cd.appendLE(dosTime)
            cd.appendLE(dosDate)
            cd.appendLE(entry.crc)
            cd.appendLE(entry.size)
            cd.appendLE(entry.size)
            cd.appendLE(UInt16(entry.nameBytes.count))
            cd.appendLE(UInt16(0))                  // extra field length
            cd.appendLE(UInt16(0))                  // file comment length
            cd.appendLE(UInt16(0))                  // disk number start
            cd.appendLE(UInt16(0))                  // internal attrs
            cd.appendLE(UInt32(0))                  // external attrs
            cd.appendLE(offsets[i])
            cd.append(entry.nameBytes)
        }

        zip.append(cd)

        // End of central directory
        zip.appendLE(UInt32(0x06054b50))
        zip.appendLE(UInt16(0))                     // disk number
        zip.appendLE(UInt16(0))                     // central dir disk
        zip.appendLE(UInt16(entries.count))
        zip.appendLE(UInt16(entries.count))
        zip.appendLE(UInt32(cd.count))
        zip.appendLE(cdOffset)
        zip.appendLE(UInt16(0))                     // comment length

        return zip
    }

    // MARK: - CRC32 (polynomial 0xEDB88320)

    private static let crc32Table: [UInt32] = (0..<256).map { i -> UInt32 in
        var c = UInt32(i)
        for _ in 0..<8 { c = (c & 1) != 0 ? (c >> 1) ^ 0xEDB88320 : c >> 1 }
        return c
    }

    private static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in data { crc = (crc >> 8) ^ crc32Table[Int((crc ^ UInt32(byte)) & 0xFF)] }
        return crc ^ 0xFFFF_FFFF
    }

    // DOS date/time for ZIP headers
    private static func dosDateTime() -> (date: UInt16, time: UInt16) {
        let c = Calendar.current
        let n = Date()
        let date = UInt16(((c.component(.year, from: n) - 1980) << 9)
                        | (c.component(.month,  from: n) << 5)
                        |  c.component(.day,    from: n))
        let time = UInt16((c.component(.hour,   from: n) << 11)
                        | (c.component(.minute, from: n) << 5)
                        | (c.component(.second, from: n) / 2))
        return (date, time)
    }

    // MARK: - XLSX XML Files

    private func buildXMLFiles(entries: [TimeEntry]) -> [(name: String, data: Data)] {
        [
            ("[Content_Types].xml",          contentTypesXML()),
            ("_rels/.rels",                  relsXML()),
            ("xl/workbook.xml",              workbookXML()),
            ("xl/_rels/workbook.xml.rels",   workbookRelsXML()),
            ("xl/styles.xml",                stylesXML()),
            ("xl/worksheets/sheet1.xml",     sheetXML(entries: entries)),
        ]
    }

    private func contentTypesXML() -> Data {
        xml("""
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
          <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
          <Default Extension="xml" ContentType="application/xml"/>
          <Override PartName="/xl/workbook.xml"
            ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
          <Override PartName="/xl/worksheets/sheet1.xml"
            ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
          <Override PartName="/xl/styles.xml"
            ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
        </Types>
        """)
    }

    private func relsXML() -> Data {
        xml("""
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1"
            Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument"
            Target="xl/workbook.xml"/>
        </Relationships>
        """)
    }

    private func workbookXML() -> Data {
        xml("""
        <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
                  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
          <sheets>
            <sheet name="TimeAudit" sheetId="1" r:id="rId1"/>
          </sheets>
        </workbook>
        """)
    }

    private func workbookRelsXML() -> Data {
        xml("""
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1"
            Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet"
            Target="worksheets/sheet1.xml"/>
          <Relationship Id="rId2"
            Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles"
            Target="styles.xml"/>
        </Relationships>
        """)
    }

    private func stylesXML() -> Data {
        // Cell format (xf) indices used in sheet:
        // 0 = default
        // 1 = header (bold)
        // 2 = productive – green  #C6EFCE
        // 3 = neutral    – gray   #E8E8E8
        // 4 = harmful    – red    #FFC7CE
        xml("""
        <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
          <fonts count="2">
            <font><sz val="11"/><name val="Calibri"/></font>
            <font><b/><sz val="11"/><name val="Calibri"/></font>
          </fonts>
          <fills count="5">
            <fill><patternFill patternType="none"/></fill>
            <fill><patternFill patternType="gray125"/></fill>
            <fill><patternFill patternType="solid"><fgColor rgb="FFC6EFCE"/></patternFill></fill>
            <fill><patternFill patternType="solid"><fgColor rgb="FFE8E8E8"/></patternFill></fill>
            <fill><patternFill patternType="solid"><fgColor rgb="FFFFC7CE"/></patternFill></fill>
          </fills>
          <borders count="1">
            <border><left/><right/><top/><bottom/><diagonal/></border>
          </borders>
          <cellStyleXfs count="1">
            <xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>
          </cellStyleXfs>
          <cellXfs count="5">
            <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
            <xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/>
            <xf numFmtId="0" fontId="0" fillId="2" borderId="0" xfId="0" applyFill="1"/>
            <xf numFmtId="0" fontId="0" fillId="3" borderId="0" xfId="0" applyFill="1"/>
            <xf numFmtId="0" fontId="0" fillId="4" borderId="0" xfId="0" applyFill="1"/>
          </cellXfs>
        </styleSheet>
        """)
    }

    private func sheetXML(entries: [TimeEntry]) -> Data {
        let dateFmt = DateFormatter()
        dateFmt.locale   = Locale(identifier: "de_DE")
        dateFmt.dateFormat = "dd.MM.yyyy"

        let timeFmt = DateFormatter()
        timeFmt.locale   = Locale(identifier: "de_DE")
        timeFmt.dateFormat = "HH:mm"

        var rows = """
        <row r="1">
          <c r="A1" s="1" t="inlineStr"><is><t>Datum</t></is></c>
          <c r="B1" s="1" t="inlineStr"><is><t>Uhrzeit</t></is></c>
          <c r="C1" s="1" t="inlineStr"><is><t>Kategorie</t></is></c>
          <c r="D1" s="1" t="inlineStr"><is><t>Kommentar</t></is></c>
          <c r="E1" s="1" t="inlineStr"><is><t>Minuten</t></is></c>
        </row>\n
        """

        for (i, entry) in entries.sorted(by: { $0.timestamp < $1.timestamp }).enumerated() {
            let r      = i + 2
            let cat    = ActivityCategory(rawValue: entry.categoryValue)
            // xf index: 2=green, 3=gray, 4=red
            let s: Int
            switch cat {
            case .productive: s = 2
            case .neutral:    s = 3
            case .harmful:    s = 4
            default:          s = 0
            }
            let date = dateFmt.string(from: entry.timestamp)
            let time = timeFmt.string(from: entry.timestamp)
            let name = cat?.displayName ?? ""
            let note = escapeXML(entry.note)

            rows += """
            <row r="\(r)">
              <c r="A\(r)" s="\(s)" t="inlineStr"><is><t>\(date)</t></is></c>
              <c r="B\(r)" s="\(s)" t="inlineStr"><is><t>\(time)</t></is></c>
              <c r="C\(r)" s="\(s)" t="inlineStr"><is><t>\(name)</t></is></c>
              <c r="D\(r)" s="\(s)" t="inlineStr"><is><t>\(note)</t></is></c>
              <c r="E\(r)" s="\(s)"><v>\(entry.intervalMinutes)</v></c>
            </row>\n
            """
        }

        return xml("""
        <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
          <cols>
            <col min="1" max="1" width="12" customWidth="1"/>
            <col min="2" max="2" width="8"  customWidth="1"/>
            <col min="3" max="3" width="20" customWidth="1"/>
            <col min="4" max="4" width="45" customWidth="1"/>
            <col min="5" max="5" width="10" customWidth="1"/>
          </cols>
          <sheetData>
            \(rows)
          </sheetData>
        </worksheet>
        """)
    }

    // MARK: - Helpers

    private func xml(_ body: String) -> Data {
        ("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n" + body)
            .data(using: .utf8)!
    }

    private func escapeXML(_ s: String) -> String {
        s.replacingOccurrences(of: "&",  with: "&amp;")
         .replacingOccurrences(of: "<",  with: "&lt;")
         .replacingOccurrences(of: ">",  with: "&gt;")
         .replacingOccurrences(of: "\"", with: "&quot;")
    }
}

// MARK: - Data helpers

private extension Data {
    mutating func appendLE<T: FixedWidthInteger>(_ value: T) {
        var le = value.littleEndian
        append(Data(bytes: &le, count: MemoryLayout<T>.size))
    }
}
