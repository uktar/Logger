//
//  Logger.swift
//  Util
//
//  Created by uktar on 2016/4/12.
//  Copyright © 2016年 chttl. All rights reserved.
//

import Foundation

enum LogLevel: Int {
    case all = 1, debug, info, warn, error, fatal, off
}

class Logger {

    fileprivate var logLevel: LogLevel = LogLevel.all
    fileprivate var logName: String = ""
    
    fileprivate var streamHandler: OutputStream?
    fileprivate var currentDate: String = ""
    
    fileprivate let writeFileQueue = DispatchQueue(label: "writeFileQueue", attributes: [])
    
    
    func setLog(level: LogLevel) {
        logLevel = level
    }
    
    init(level: LogLevel, name: String = "default") {
        logLevel = level
        logName = name
        currentDate = getDateString()
        openFile()
    }
    
    deinit {
        closeFile()
    }
    
    fileprivate func doLog(_ level: LogLevel, fileName: String, funcName: String, line: Int, logStr: String) {
        if level.rawValue >= logLevel.rawValue  {
            
            let pathNameArr = fileName.characters.split{$0 == "/"}.map { String($0) }
            var file = fileName
            if pathNameArr.last != nil {
                file = pathNameArr.last!
            }
            
            let funcNameArr = funcName.characters.split{$0 == "("}.map { String($0) }
            var funcNameNoParam = funcName
            if funcNameArr.first != nil {
                funcNameNoParam = funcNameArr.first!
            }
            
            let now = getTodayString()
       
            switch (level) {
            case .debug:
                let outStr = "\(now) [DEBUG] [\(file):\(line)] [\(funcNameNoParam)] \(logStr)"
                print("\(outStr)")
                writeFile(outStr + "\n")
            case .info:
                let outStr = "\(now) [INFO] [\(file):\(line)] [\(funcNameNoParam)] \(logStr)"
                print("\(outStr)")
                writeFile(outStr + "\n")
            case .warn:
                let outStr = "\(now) [WARN] [\(file):\(line)] [\(funcNameNoParam)] \(logStr)"
                print("\(outStr)")
                writeFile(outStr + "\n")
            case .error:
                let outStr = "\(now) [ERROR] [\(file):\(line)] [\(funcNameNoParam)] \(logStr)"
                print("\(outStr)")
                writeFile(outStr + "\n")
            case .fatal:
                let outStr = "\(now) [FATAL] [\(file):\(line)] [\(funcNameNoParam)] \(logStr)"
                print("\(outStr)")
                writeFile(outStr + "\n")
            case .off:
                break
            default:
                let outStr = "\(now) [\(file):\(line)] [\(funcNameNoParam)] \(logStr)"
                print("\(outStr)")
                writeFile(outStr + "\n")
            }
        }
    }
    
    func debug(_ content: String, fileName: String = #file, funcName: String = #function, line: Int = #line) {
        doLog(.debug, fileName: fileName, funcName: funcName, line: line, logStr: content)
    }
    
    func info(_ content: String, fileName: String = #file, funcName: String = #function, line: Int = #line) {
        doLog(.info, fileName: fileName, funcName: funcName, line: line, logStr: content)
    }
    
    func warn(_ content: String, fileName: String = #file, funcName: String = #function, line: Int = #line) {
        doLog(.warn, fileName: fileName, funcName: funcName, line: line, logStr: content)
    }
    
    func error(_ content: String, fileName: String = #file, funcName: String = #function, line: Int = #line) {
        doLog(.error, fileName: fileName, funcName: funcName, line: line, logStr: content)
    }
    
    func fatal(_ content: String, fileName: String = #file, funcName: String = #function, line: Int = #line) {
        doLog(.fatal, fileName: fileName, funcName: funcName, line: line, logStr: content)
    }
    

    
    fileprivate func getTodayString() -> String {
        let now = Date()
        let form = DateFormatter()
        form.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let str = form.string(from: now)
        
        return str
        
        
    }
    
    fileprivate func getDateString() -> String {
        let now = Date()
        let form = DateFormatter()
        form.dateFormat = "yyyyMMdd"
        let str = form.string(from: now)
        
        return str
    }
    
    fileprivate func openFile() {
        if streamHandler != nil {
            closeFile()
        }
        
        let file = logName + "_" + currentDate + ".log"
        do {
            let documents = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let directory = documents.appendingPathComponent("logs", isDirectory: true)
                
            if FileManager.default.fileExists(atPath: directory.path) == false {
                do {
                    try FileManager.default.createDirectory(atPath: directory.path, withIntermediateDirectories: false, attributes: nil)
                } catch let error as NSError {
                    print("\(error.localizedDescription)")
                }
            }
            
            let path = directory.appendingPathComponent(file).path
            print("log path is \(path)")
            streamHandler = OutputStream(toFileAtPath: path, append: true)
            if streamHandler != nil {
                streamHandler!.open()
            }
        } catch {
            print("Unable to open directory")
        }
        
    }

    fileprivate func switchFile() {
        let newDate = getDateString()
        if currentDate != newDate {
            // set date of the new file
            currentDate = newDate
            // open new file
            openFile()
        }
    }
    
    fileprivate func closeFile() {
        streamHandler?.close()
        streamHandler = nil
    }
    
    fileprivate func writeFile(_ content: String) {
    
        switchFile()
        
        if streamHandler == nil {
            openFile()
        }
        
        if streamHandler != nil {
            let text = content
            writeFileQueue.async {
                _ = self.streamHandler!.write(text)
            }
            
        } else {
            print("Unable to open file")
        }
        
    }
    
}


// reference from http://stackoverflow.com/questions/26989493/how-to-open-file-and-append-a-string-in-it-swift
extension OutputStream {
    
    /// Write String to outputStream
    ///
    /// - parameter string:                The string to write.
    /// - parameter encoding:              The NSStringEncoding to use when writing the string. This will default to UTF8.
    /// - parameter allowLossyConversion:  Whether to permit lossy conversion when writing the string.
    ///
    /// - returns:                         Return total number of bytes written upon success. Return -1 upon failure.
    
    func write(_ string: String, encoding: String.Encoding = String.Encoding.utf8, allowLossyConversion: Bool = true) -> Int {
        if let data = string.data(using: encoding, allowLossyConversion: allowLossyConversion) {
            var bytes = (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count)
            var bytesRemaining = data.count
            var totalBytesWritten = 0
            
            while bytesRemaining > 0 {
                let bytesWritten = self.write(bytes, maxLength: bytesRemaining)
                if bytesWritten < 0 {
                    return -1
                }
                
                bytesRemaining -= bytesWritten
                bytes += bytesWritten
                totalBytesWritten += bytesWritten
            }
            
            return totalBytesWritten
        }
        
        return -1
    }
    
}


