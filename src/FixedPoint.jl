module FixedPoint

import Base: convert, promote_rule, show, showcompact, isinteger, abs

export FixedPoint, Fixed32

abstract FixedPoint <: Real

# 32-bit fixed point; parameter `f` is the number of fraction bits
immutable Fixed32{f} <: FixedPoint
    i::Int32

    # constructor for manipulating the representation;
    # selected by passing an extra dummy argument
    Fixed32(i::Integer,_) = new(i)

    Fixed32(x) = convert(Fixed32{f}, x)
end

Fixed32(x::Real) = convert(Fixed32{16}, x)

# comparisons
=={f}(x::Fixed32{f}, y::Fixed32{f}) = x.i == y.i
< {f}(x::Fixed32{f}, y::Fixed32{f}) = x.i <  y.i
<={f}(x::Fixed32{f}, y::Fixed32{f}) = x.i <= y.i

# predicates
isinteger{f}(x::Fixed32{f}) = (x.i&(1<<f-1)) == 0

# basic operators
-{f}(x::Fixed32{f}) = Fixed32{f}(-x.i,0)
abs{f}(x::Fixed32{f}) = Fixed32{f}(abs(x.i),0)

+{f}(x::Fixed32{f}, y::Fixed32{f}) = Fixed32{f}(x.i+y.i,0)
-{f}(x::Fixed32{f}, y::Fixed32{f}) = Fixed32{f}(x.i-y.i,0)
*{f}(x::Fixed32{f}, y::Fixed32{f}) = Fixed32{f}((Base.widemul(x.i,y.i)+(int64(1)<<(f-1)))>>f,0)
/{f}(x::Fixed32{f}, y::Fixed32{f}) = Fixed32{f}(div((int64(x.i)<<f)+(int64(1)<<(f-1)), y.i),0)
# without rounding:
#*{f}(x::Fixed32{f}, y::Fixed32{f}) = Fixed32{f}(Base.widemul(x.i,y.i)>>f,0)
#/{f}(x::Fixed32{f}, y::Fixed32{f}) = Fixed32{f}(div(int64(x.i)<<f, y.i),0)

# conversions and promotions
convert{f}(::Type{Fixed32{f}}, x::Integer) = Fixed32{f}(x<<f,0)
convert{f}(::Type{Fixed32{f}}, x::FloatingPoint) = Fixed32{f}(itrunc(x)<<f + int32(rem(x,1)*(1<<f)),0)
convert{f}(::Type{Fixed32{f}}, x::Rational) = Fixed32{f}(x.num)/Fixed32{f}(x.den)

convert{f}(::Type{BigFloat}, x::Fixed32{f}) =
    convert(BigFloat,x.i>>f) + convert(BigFloat,x.i&(1<<f - 1))/convert(BigFloat,1<<f)
convert{T<:FloatingPoint, f}(::Type{T}, x::Fixed32{f}) =
    convert(T,x.i>>f) + convert(T,x.i&(1<<f - 1))/convert(T,1<<f)

convert(::Type{Bool}, x::Fixed32) = x.i!=0
function convert{T<:Integer, f}(::Type{T}, x::Fixed32{f})
    isinteger(x) || throw(InexactError())
    x.i>>f
end

convert{T<:Rational, f}(::Type{T}, x::Fixed32{f}) =
    convert(T, x.i>>f + (x.i&(1<<f-1))//(1<<f))

promote_rule{f,T<:Integer}(ft::Type{Fixed32{f}}, ::Type{T}) = ft
promote_rule{f,T<:FloatingPoint}(::Type{Fixed32{f}}, ::Type{T}) = T

# printing
function show(io::IO, x::Fixed32)
    print(io, typeof(x))
    print(io, "(")
    showcompact(io, x)
    print(io, ")")
end
const _log2_10 = 3.321928094887362
showcompact{f}(io::IO, x::Fixed32{f}) = show(io, round(convert(Float64,x), iceil(f/_log2_10)))

end # module
