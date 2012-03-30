/*
 * Copyright (c) 2005-2008, The haXe Project Contributors
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
package haxe.io;

class BytesBuffer {

	#if neko
	var b : Void; // neko string buffer
	#elseif flash9
	var b : flash.utils.ByteArray;
	#elseif php
	var b : String;
	#elseif cpp
	var b : BytesData;
	#elseif js
	var b : Dynamic; // Bytes for typedArray, Array<Int> if not supported 
	var size : Int;
	#else
	var b : Array<Int>;
	#end

	public function new() {
		#if neko
		b = untyped StringBuf.__make();
		#elseif flash9
		b = new flash.utils.ByteArray();
		#elseif php
		b = "";
		#elseif cpp
		b = new BytesData();
		#elseif js
		b = Bytes.alloc(0);
		#else
		b = new Array();
		#end
	}

	public inline function addByte( byte : Int ) {
		#if neko
		untyped StringBuf.__add_char(b,byte);
		#elseif flash9
		b.writeByte(byte);
		#elseif php
		b += untyped __call__("chr", byte);
		#elseif cpp
		b.push(untyped byte);
		#elseif js 
		if (js.Lib.isTypedArraySupported) {
			if (size == b.length) { // we need to grow?
				var newSize = Math.max(Math.max(b.length * 2), 4); // duplicate size
				growTo(newSize);
			}
			b[size++] = byte;
		}
		else {
			b.push(byte);
		}
		#else
		b.push(byte);
		#end
	}
	
	#if js 
	// Grows the Uint8Array to the desired size
	private function growTo(length:Int) : Void {
		if (length > b.length) { // do we need to resize?
			var oldB = b; // create new buffer
			b = Bytes.alloc(length);
			b.blit(0, oldB, 0, Math.min(b.length, oldB.length)); // blit old data to new buffer
		}
	}
	#end 

	public inline function add( src : Bytes ) {
		#if neko
		untyped StringBuf.__add(b,src.getData());
		#elseif flash9
		b.writeBytes(src.getData());
		#elseif php
		b += cast src.getData();
		#elseif js
		if (js.Lib.isTypedArraySupported) {
			// grow array that we can store the bytes 
			var newSize = size + src.length;
			growTo(newSize);
			// blit the bytes over			
			b.blit(size, src, 0, src.length);
			size += src.length;
		}
		else {
			var b1 = b;
			var b2 = src.getData();
			for( i in 0...src.length )
				b.push(b2[i]);
		}
		#else
		var b1 = b;
		var b2 = src.getData();
		for( i in 0...src.length )
			b.push(b2[i]);
		#end
	}

	public inline function addBytes( src : Bytes, pos : Int, len : Int ) {
		#if !neko
		if( pos < 0 || len < 0 || pos + len > src.length ) throw Error.OutsideBounds;
		#end
		#if neko
		try untyped StringBuf.__add_sub(b,src.getData(),pos,len) catch( e : Dynamic ) throw Error.OutsideBounds;
		#elseif flash9
		b.writeBytes(src.getData(),pos,len);
		#elseif php
		b += untyped __call__("substr", src.b, pos, len);
		#elseif js
		if (js.Lib.isTypedArraySupported) {
			// grow array that we can store the bytes 
			var newSize = size + len;
			growTo(newSize);
			// blit the bytes over			
			b.blit(size, src, src, len);
			size += length;
		}
		else {
			var b1 = b;
			var b2 = src.getData();
			for( i in pos...pos+len )
				b.push(b2[i]);
		}		
		#else
		var b1 = b;
		var b2 = src.getData();
		for( i in pos...pos+len )
			b.push(b2[i]);
		#end
	}

	/**
		Returns either a copy or a reference of the current bytes.
		Once called, the buffer can no longer be used.
	**/
	public function getBytes() : Bytes untyped {
		#if neko
		var str = StringBuf.__string(b);
		var bytes = new Bytes(__dollar__ssize(str),str);
		#elseif flash9
		var bytes = new Bytes(b.length,b);
		b.position = 0;
		#elseif php
		var bytes = new Bytes(b.length, cast b);
		#elseif js
		var bytes:Bytes;
		if (js.Lib.isTypedArraySupported) {
			bytes = new Bytes(b.length, b.subarray(0, size));
		}
		else {
			bytes =  new Bytes(b.length, b);
		}
		#else
		var bytes = new Bytes(b.length,b);
		#end
		b = null;
		return bytes;
	}

}
