% 15-Mar-2012 10:02:22 A�ado mancha2borde, que s�lo debe usarse para
% arreglar fallos de programas anteriores
% APE 24 feb 12

% (C) 2014 Alfonso P�rez Escudero, Gonzalo G. de Polavieja, Consejo Superior de Investigaciones Cient�ficas

% El uso de mancha2borde no deber�a ser necesario en general. S�lo sirve
% para los casos en los que avi2segm se haya ejecutado antes del fix del 14
% de marzo de 2012.

function idtrozos=mancha2id2idtrozos(datosegm,trozos,solapos,mancha2id,mancha2borde)

if nargin<5 || isempty(mancha2borde)
    mancha2borde=false(size(trozos));
end

n_trozos=max(trozos(:));
idtrozos=NaN(n_trozos,datosegm.n_peces);
for c_trozos=1:n_trozos
    ind=find(trozos==c_trozos & ~mancha2borde);
    if ~isempty(ind)
        try
        [idtrozos(c_trozos,:),mat_id]=idmanchas2idtrozo(datosegm,mancha2id(ind),solapos(ind));
        catch
            keyboard
        end
    end
end % c_trozos
