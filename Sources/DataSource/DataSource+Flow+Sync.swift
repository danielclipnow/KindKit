//
//  KindKit
//

import Foundation

public extension DataSource.Flow {
    
    final class Sync<
        Input : IFlowResult,
        DataSource : ISyncDataSource
    > : IFlowOperator where
        Input.Failure == DataSource.Failure
    {
        
        public typealias Input = Input
        public typealias Output = Result< DataSource.Success, DataSource.Failure >
        
        private let _dataSource: DataSource
        private var _next: IFlowPipe!
        
        init(
            _ dataSource: DataSource
        ) {
            self._dataSource = dataSource
            self._setup()
        }
        
        public func subscribe(next: IFlowPipe) {
            self._next = next
        }
        
        public func receive(value: Input.Success) {
            self._dataSource.syncIfNeeded()
        }
        
        public func receive(error: Input.Failure) {
            self._dataSource.cancel()
            self._next.send(error: error)
            self._next.completed()
        }
        
        public func completed() {
        }
        
        public func cancel() {
            self._dataSource.cancel()
            self._next.cancel()
        }
        
    }
    
}

private extension DataSource.Flow.Sync {
    
    func _setup() {
        self._dataSource.onFinish.link(self, { $0._onFinish($1) })
    }
    
    func _onFinish(_ result: Output) {
        self._next.send(value: result)
        self._next.completed()
    }
    
}

extension IFlowOperator {
    
    func dataSource<
        DataSource : ISyncDataSource
    >(
        _ dataSource: DataSource
    ) -> KindKit.DataSource.Flow.Sync< Output, DataSource > where
        Output.Failure == DataSource.Failure
    {
        let next = KindKit.DataSource.Flow.Sync< Output, DataSource >(dataSource)
        self.subscribe(next: next)
        return next
    }
    
}

public extension Flow.Builder {
    
    func dataSource<
        DataSource : ISyncDataSource
    >(
        _ dataSource: DataSource
    ) -> Flow.Head.Builder< KindKit.DataSource.Flow.Sync< Input, DataSource > > where
        Input.Failure == DataSource.Failure
    {
        return .init(head: .init(dataSource))
    }
    
}

public extension Flow.Head.Builder {
    
    func dataSource<
        DataSource : ISyncDataSource
    >(
        _ dataSource: DataSource
    ) -> Flow.Chain.Builder< Head, KindKit.DataSource.Flow.Sync< Head.Output, DataSource > > where
        Head.Output.Failure == DataSource.Failure
    {
        return .init(head: self.head, tail: self.head.dataSource(dataSource))
    }
    
}

public extension Flow.Chain.Builder {
    
    func dataSource<
        DataSource : ISyncDataSource
    >(
        _ dataSource: DataSource
    ) -> Flow.Chain.Builder< Head, KindKit.DataSource.Flow.Sync< Tail.Output, DataSource > > where
        Tail.Output.Failure == DataSource.Failure
    {
        return .init(head: self.head, tail: self.tail.dataSource(dataSource))
    }
    
}