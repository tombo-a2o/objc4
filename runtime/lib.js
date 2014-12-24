mergeInto(LibraryManager.library, {
	/*
	objc_msgSend: function(self, sel, param1) {
		if(!self) return null;

		var cls = self.isa;
		var cache = cls.cache;

		var mask = cache._mask;
		var bucket_first = cache._buckets;
		
	},
	*/
	_objc_msgForward: function() {
		throw "_objc_msgForward is unimplemented";
	},
	_objc_msgForward_impcache: function() {
		throw "_objc_msgForward_impcache is unimplemented";
	},
	_objc_msgSend_uncached_impcache: function() {
		throw "unimplemented";
	},
	cache_getImp: function() {
		throw "unimplemented";
	},
	_objc_ignored_method: function() {
		throw "unimplemented";
	}
});

