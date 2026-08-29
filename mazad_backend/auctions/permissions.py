from rest_framework import permissions


class IsOwnerOrReadOnly(permissions.BasePermission):
    """Only the seller who created a listing can edit or delete it."""

    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:  # GET, HEAD, OPTIONS
            return True
        return obj.seller_id == request.user.id