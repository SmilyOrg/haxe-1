/*
 * Copyright (c) 2005, The haXe Project Contributors
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
package haxe;

class AsyncDebugConnection implements AsyncConnection, implements Dynamic<AsyncDebugConnection> {

	var __data : Dynamic;
	var __path : Array<String>; // not used there
	var lastCalls : List<{ path : Array<String>, params : Array<Dynamic> }>;

	public function new(cnx) {
		__data = cnx;
		lastCalls = new List();
		onError = cnx.onError;
		var me = this;
		cnx.onError = function(e) {
			var l = me.lastCalls.pop();
			if( l != null )
				me.onErrorDisplay(l.path,l.params,e);
			me.onError(e);
		}
	}

	function __resolve(field : String) : AsyncConnection {
		var s = new AsyncDebugConnection(__data.__resolve(field));
		s.lastCalls = lastCalls;
		// late binding of events
		var me = this;
		s.onError = function(e) { me.onError(e); };
		s.onCall = function(p,pa) { me.onCall(p,pa); };
		s.onResult = function(p,pa,r) { me.onResult(p,pa,r); };
		me.onErrorDisplay = function(p,pa,e) { me.onErrorDisplay(p,pa,e); };
		return s;
	}

	public function onError( err : Dynamic ) {
	}

	public function onErrorDisplay( path : Array<String>, params : Array<Dynamic>, err : Dynamic ) {
		trace(path.join(".")+"("+params.join(",")+") = ERROR "+Std.string(err));
	}

	public function onCall( path : Array<String>, params : Array<Dynamic> ) {
	}

	public function onResult( path : Array<String>, params : Array<Dynamic>, result : Dynamic ) {
		trace(path.join(".")+"("+params.join(",")+") = "+Std.string(result));
	}

	public function call( params : Array<Dynamic>, onData : Dynamic -> Void ) : Void {
		lastCalls.add({ path : __data.__path, params : params });
		onCall(__data.__path,params);
		var me = this;
		__data.call(params,function(r) {
			var x = me.lastCalls.pop();
			if( x != null )
				me.onResult(x.path,x.params,r);
			if( onData != null )
				onData(r);
		});
	}

}
